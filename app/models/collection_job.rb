# NOTE - assuming #update returns an accurate row_count (it seems to):
class CollectionJob < ActiveRecord::Base

  MAX_ITEMS_TO_REINDEX = 250

  # Columns that users are allowed to copy when they don't own the source:
  SAFE_COLUMNS = %w(collected_item_id collected_item_type).join(',')

  attr_accessible :all_items, :collection, :command, :finished_at, :item_count, :target_collection,
                  :user, :overwrite

  belongs_to :collection
  belongs_to :target_collection, :class_name => 'Collection'
  belongs_to :user

  has_and_belongs_to_many :collection_items

  validates_presence_of :target_collection_id, :if => :target_needed?
  # Simple enumeration; NOTE these must be defined as methods:
  validates :command, :inclusion => { :in => %w(copy move remove) }

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
    CollectionJob.fail_if_user_cannot_edit_collection(:source, params)
    CollectionJob.validate_create_and_run(params.reverse_merge(:command => 'remove'))
  end

  def run
    affected = method(command).call # Call the method with the name in the 'command' value.
    count = affected.respond_to?(:length) ? affected.length : affected
    write_attribute(:item_count, count)
    write_attribute(:finished_at, Time.now.in_time_zone('UTC').to_s)
    if count > 0
      collection.set_relevance unless command == 'copy'
      target_collection.set_relevance if target_needed?
      if command == 'remove'
        if all_items?
          SolrCollections.remove_collection_items(collection_items)
        else
          SolrCollections.remove_collection(collection)
        end
      else
        if count < MAX_ITEMS_TO_REINDEX
          SolrCollections.reindex_collection_items(affected)
        else
          SolrCollections.reindex_collection(collection) unless command == 'copy'
          SolrCollections.reindex_collection(target_collection) if target_needed?
        end
      end
    end
  end

  # NOTE - Sadly, this needs to be public because it's called by the class methods.
  def fail_if_no_scope
    raise EOL::Exceptions::CollectionJobRequiresScope if collection_items.empty? && ! all_items
  end

private

  def self.fail_if_user_cannot_edit_collection(which, params = {})
    raise EOL::Exceptions::SecurityViolation unless params[:user] && params[:user].can_edit_collection?(params[which])
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

  # TODO - this will lock the table. (INSERT SELECT always does.) We want to change this to select first and
  # then handle the insert either in blocks or using a file or some-such.
  def copy
    transaction do
      delete_duplicates if overwrite? # Since we're overwriting, we need to get rid of conflicts
      # Users only get all the ancillary data (annotation and sorts and the like) if they own the source:
      columns = user_owns_source? ? unhandled_columns : SAFE_COLUMNS
      affected = watch_inserts do
        CollectionItem.connection.update(ActiveRecord::Base.sanitize_sql_array([%(
          INSERT IGNORE INTO collection_items (collection_id, #{columns})
            SELECT ?, #{columns}
            FROM collection_items
            WHERE #{source_where_clause}
        ),
        target_collection_id,
        source_where_argument]))
      end
      copy_references if user_owns_source?
      affected
    end
  end

  # Uuuuuhuhghghghhg-h-h-h.  This will be SO slow on large collections with lots of refs. Fortunately, that's not many.
  def copy_references
    Ref.joins(:collection_items).where("collection_items.#{source_where_clause}", source_where_argument).each do |ref|
      ref.collection_items.each do |collection_item|
        new_collection_item = CollectionItem.where(collected_item_id: collection_item.collected_item_id, 
                                                   collected_item_type: collection_item.collected_item_type,
                                                   collection_id: target_collection.id).first
        new_collection_item.refs << ref if new_collection_item
      end
    end
  end

  def move
    ids_before_move = target_collection.collection_items.select("id").map(&:id) # Possibly expensive on super-large collections, but we need it.
    transaction do
      delete_duplicates if overwrite? # Since we're overwriting, we need to get rid of conflicts
      CollectionItem.connection.update(ActiveRecord::Base.sanitize_sql_array([%{
        UPDATE IGNORE collection_items
          SET collection_id = ?
          WHERE #{source_where_clause}
      },
      target_collection_id,
      source_where_argument]))
    end
    if ids_before_move.empty?
      target_collection.reload.collection_items
    else
      CollectionItem.where(["collection_id = ? AND NOT id IN (?)", target_collection_id, ids_before_move])
    end
  end

  def remove
    CollectionItem.delete_all([source_where_clause, source_where_argument])
  end

  def source_where_clause
    if all_items?
      'collection_id = ?'
    else
      'id IN (?)'
    end
  end

  def source_where_argument
    if all_items?
      collection_id
    else
      collection_item_ids
    end
  end

  # NOTE - this should probably only be done as part of a transaction! Your gun, your foot.
  def delete_duplicates
    CollectionItem.delete_all(['ID in (?)', duplicates.map(&:id)])
  end

  def duplicates
    @duplicates ||=
      CollectionItem.find_by_sql(ActiveRecord::Base.sanitize_sql_array([%{
        SELECT target.id
        FROM collection_items source
          INNER JOIN collection_items target
            ON source.collected_item_type = target.collected_item_type
              AND source.collected_item_id = target.collected_item_id
        WHERE
          source.#{source_where_clause}
          AND target.collection_id = ?
      }, source_where_argument, target_collection.id]))
  end

  # Returns new collection items in target collection:
  def watch_inserts(&block)
    last_id = CollectionItem.maximum('id')
    yield
    if last_id
      CollectionItem.where(['id > ? AND collection_id = ?', last_id, target_collection_id])
    else # Really only useful in tests:
      CollectionItem.where(collection_id: target_collection_id)
    end
  end

  def collection_items_matching(items)
    ids = items.map { |item| [item.collected_item_type, item.collected_item_id] }
    collection_items.select do |item|
      ids.include?([item.collected_item_type, item.collected_item_id]) 
    end
  end

  def unhandled_columns
    return @columns if defined?(@columns)
    columns = CollectionItem.column_names
    columns.delete('id') # Because that's auto-gen'd
    columns.delete('collection_id') # Because we are specifying that.
    @columns = columns.join(',')
  end

  def user_owns_source?
    @user_owns_source ||= user.can_edit_collection?(collection)
  end

end
