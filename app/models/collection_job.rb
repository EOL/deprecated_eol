# NOTE - assuming #update returns an accurate row_count (it seems to):
class CollectionJob < ActiveRecord::Base

  attr_accessible :all_items, :collection, :command, :finished_at, :item_count, :target_collection,
                  :user, :overwrite

  belongs_to :collection
  belongs_to :target_collection, :class_name => 'Collection'
  belongs_to :user

  has_and_belongs_to_many :collection_items

  validates_presence_of :target_collection_id, :if => :target_needed?

  def self.copy(params = {})
    CollectionJob.fail_if_user_cannot_edit_collection(:target, params)
    CollectionJob.validate_create_and_run(params.reverse_merge(:command => 'copy'))
  end

  def self.move(params = {})
    CollectionJob.fail_if_user_cannot_edit_collection(:source, params)
    CollectionJob.fail_if_user_cannot_edit_collection(:target, params)
    CollectionJob.validate_create_and_run(params.reverse_merge(:command => 'move'))
  end

  def self.remove(params = {})
    CollectionJob.validate_create_and_run(params.reverse_merge(:command => 'remove'))
  end

  # NOTE - returns rows affected.
  def run
    row_count = case command
                when 'copy'
                  copy
                when 'move'
                  move
                when 'remove'
                  remove
                end
    write_attribute(:item_count, row_count)
    write_attribute(:finished_at, Time.now.in_time_zone('UTC').to_s)
    collection.set_relevance
    if target_needed?
      target_collection.set_relevance if target_needed?
      update_solr_intelligently(target_collection, row_count)
    end
    row_count
  end

  # NOTE - Sadly, this needs to be public because it's called by the class methods.
  def fail_if_no_scope
    raise EOL::Exceptions::CollectionJobRequiresScope if collection_items.empty? && ! all_items
  end

private

  def self.fail_if_user_cannot_edit_collection(params = {})
    raise EOL::Exceptions::SecurityViolation unless params[:user] && params[:user].can_edit_collection?(params[:target])
  end

  # NOTE - I *want* this to throw exceptions on any validation errors... though I might change my mind later:
  def self.validate_create_and_run(params = {})
    job = CollectionJob.create!(:collection => params[:source],
                                :command => params[:command],
                                :all_items => params[:all_items],
                                :target_collection => params[:target],
                                :overwrite => params[:overwrite],
                                :user => params[:user])
    job.collection_item_ids = params[:collection_item_ids] if params[:collection_item_ids]
    job.fail_if_no_scope
    job.run # TODO - we want to delay this job... but not right now. ...we're... delaying... the delaying...
    job
  end

  def target_needed?
    command == 'copy' || command == 'move'
  end

  def copy
    inserted = if all_items?
                 insert_copied_items('collection_id = ?', collection_id)
               else
                 insert_copied_items('id IN (?)', collection_item_ids)
               end
    SolrCollections.reindex_collection(all_items? ? collection : collection_items_matching(inserted))
    SolrCollections.reindex_collection_items(inserted)
    affected_items.count
  end

  # TODO - this will lock the table. (INSERT SELECT always does.) We want to change this to select first and
  # then handle the insert either in blocks or using a file or some-such.
  def insert_copied_items(where_clause, where_argument)
    watch_inserts do
      CollectionItem.connection.update(ActiveRecord::Base.sanitize_sql_array([%Q{
        INSERT IGNORE INTO collection_items (collection_id, collected_item_id, collected_item_type)
          SELECT ?, collected_item_id, collected_item_type
          FROM collection_items
          WHERE #{where_clause}
      },
      target_collection_id,
      where_argument]))
    end
  end

  def move
    all_items? ? move_all : move_some
  end

  # YOU WERE HERE - this gets the duplicates (for an "all" operation, anyway)... which you can use
  # to determine which collection items to actually work on.  No more need to 'ignore'...
  # So, convert this to be able to select on collection_item_ids, much like #insert_copied_items ... then change the algorithms to handle duplicates intelligently.
  def duplicates
    CollectionItem.find_by_sql(ActiveRecord::Base.sanitize_sql_array([%Q{
      SELECT source.id
      FROM collection_items source
        INNER JOIN collection_items target
          ON source.collected_item_type = target.collected_item_type
            AND source.collected_item_id = target.collected_item_id
      WHERE
        source.collection_id = ?
        AND target.collection_id = ?
    }, source.id, target.id]))
  end

  def move_all
    manually_count_moves do
      CollectionItem.connection.update(ActiveRecord::Base.sanitize_sql_array([%q{
        UPDATE IGNORE collection_items
          SET collection_id = ?
          WHERE collection_id = ?
      },
      target_collection_id,
      collection_id]))
      SolrCollections.reindex_collection(collection)
      # TODO - we should probably get a list of only the items that moved and just index those:
      SolrCollections.reindex_collection(target_collection)
    end
  end

  def move_some
    manually_count_moves do
      CollectionItem.connection.update(ActiveRecord::Base.sanitize_sql_array([%q{
        UPDATE IGNORE collection_items
          SET collection_id = ?
          WHERE id IN (?)
      },
      target_collection_id,
      collection_item_ids]))
      # TODO - we should get a list of collection_items actually affected:
      SolrCollections.reindex_collection_items(collection_items)
    end
  end

  # For some reason, UPDATE IGNORE doesn't ignore the ignores, here, when counting affected rows.
  # That is to say, the rows end up correct (duplicates are ignored), but the return val of the command
  # counts those ignores as if they were successful. You get the wrong count. So we do it manually:
  def manually_count_moves(&block)
    before = collection.collection_items.count
    yield
    before - collection.collection_items.count
  end

  # Returns new collection items in target collection:
  def watch_inserts(&block)
    last_id = CollectionItem.maximum('id')
    yield
    CollectionItem.all.where(['id > ? AND collection_id = ?', last_id, target_collection_idi])
  end

  def remove
    all_items? ? remove_all : remove_some
  end

  def remove_all
    count = CollectionItem.delete_all(["collection_id = ?", collection_id])
    SolrCollections.remove_collection(collection)
    count
  end

  def remove_some
    count = CollectionItem.delete_all(["id IN (?)", collection_item_ids])
    SolrCollections.remove_collection_items(collection_items)
    count
  end

  def collection_items_matching(items)
    ids = items.map { |item| [item.collected_item_type, item.collected_item_id] }
    collection_items.select do |item|
      ids.include?([item.collected_item_type, item.collected_item_id]) 
    end
  end
end
