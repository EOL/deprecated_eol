# NOTE - assuming #update returns an accurate row_count (it seems to):
class CollectionJob < ActiveRecord::Base

  VALID_COMMANDS = %w(copy move remove)

  # Columns that users are allowed to copy when they don't own the source:
  SAFE_COLUMNS = %w(collected_item_id collected_item_type).join(',')

  attr_accessible :all_items, :collection, :command, :finished_at, :item_count, :collections,
                  :user, :overwrite, # Needed by web form:
                  :collection_item_ids, :collection_ids, :collection_id

  belongs_to :collection
  belongs_to :user

  has_and_belongs_to_many :collection_items
  has_and_belongs_to_many :collections # NOTE - these are 'target' collections.

  validates_presence_of :user
  validates_presence_of :collections, if: :target_needed?
  # Simple enumeration; NOTE these must be defined as methods:
  validates :command, inclusion: { in: VALID_COMMANDS }
  validates_presence_of :collection_items, unless: :all_items?
  validate :user_can_edit_source, unless: :copy?
  validate :user_can_edit_targets, unless: :remove?

  def run
    # TODO - second argument to constructor should be an I18n key for a human-readable error.
    raise EOL::Exceptions::SecurityViolation unless valid?
    affected = method(command).call # Call the method with the name in the 'command' value.
    count = affected.respond_to?(:length) ? affected.length : affected
    write_attribute(:item_count, count)
    write_attribute(:finished_at, Time.now.in_time_zone('UTC').to_s)
    if count > 0
      collection.set_relevance unless copy?
      if target_needed?
        collections.each do |target_collection|
          target_collection.set_relevance
        end
      end
      reindex(affected)
    end
  end

  def target_needed?
    copy? || move?
  end

  def copy?
    command == 'copy'
  end

  def move?
    command == 'move'
  end

  def remove?
    command == 'remove'
  end

  def missing_targets?
    target_needed? && collections.blank?
  end

  def has_items?
    all_items? || ! collection_items.blank?
  end

private

  def user_can_edit_source
    unless user.can_edit_collection?(collection)
      errors[:base] << I18n.t(:collection_job_error_user_cannot_access_source)
    end
  end

  def user_can_edit_targets
    collections.each do |target_collection|
      unless user.can_edit_collection?(target_collection)
        errors[:base] << I18n.t(:collection_job_error_user_cannot_access_target)
      end
    end
  end

  # TODO - this will lock the table. (INSERT SELECT always does.) We want to change this to select first and
  # then handle the insert either in blocks or using a file or some-such.
  def copy
    transaction do
      delete_duplicates if overwrite? # Since we're overwriting, we need to get rid of conflicts
      # Users only get all the ancillary data (annotation and sorts and the like) if they own the source:
      columns = user_owns_source? ? unhandled_columns : SAFE_COLUMNS
      affected = watch_inserts do
        collections.each do |target_collection|
          CollectionItem.connection.update(ActiveRecord::Base.sanitize_sql_array([%(
            INSERT IGNORE INTO collection_items (collection_id, #{columns})
              SELECT ?, #{columns}
              FROM collection_items
              WHERE #{source_where_clause}
          ),
          target_collection.id,
          source_where_argument]))
        end
      end
      copy_references if user_owns_source?
      affected
    end
  end

  # Uuuuuhuhghghghhg-h-h-h.  This will be SO slow on large collections with lots of refs. Fortunately, that's not many.
  def copy_references
    Ref.joins(:collection_items).where("collection_items.#{source_where_clause}", source_where_argument).each do |ref|
      ref.collection_items.each do |collection_item|
        collections.each do |target_collection|
          new_collection_item = CollectionItem.where(collected_item_id: collection_item.collected_item_id, 
                                                     collected_item_type: collection_item.collected_item_type,
                                                     collection_id: target_collection.id).first
          new_collection_item.refs << ref if new_collection_item && ! new_collection_item.refs.include?(ref)
        end
      end
    end
  end

  def move
    ids_before_move = collections.flat_map { |c| c.collection_items.select('id').map(&:id) } # Possibly expensive on super-large collections, but we need it.
    transaction do
      delete_duplicates if overwrite? # Since we're overwriting, we need to get rid of conflicts
      collections.each do |target_collection|
        CollectionItem.connection.update(ActiveRecord::Base.sanitize_sql_array([%{
          UPDATE IGNORE collection_items
            SET collection_id = ?
            WHERE #{source_where_clause}
        },
        target_collection.id,
        source_where_argument]))
      end
    end
    if ids_before_move.empty?
      collections.flat_map { |c| c.reload.collection_items }
    else
      CollectionItem.where(["collection_id IN (?) AND NOT id IN (?)", collections.map(&:id), ids_before_move])
    end
  end

  def remove
    CollectionItem.delete_all([source_where_clause, source_where_argument])
  end

  def reindex(affected)
    if remove?
      # update collection items count
      collection.update_attributes(collection_items_count: collection.collection_items.count)
      if all_items?
        EOL::Solr::CollectionItemsCoreRebuilder.remove_collection(collection)        
      else
        EOL::Solr::CollectionItemsCoreRebuilder.remove_collection_items(collection_items)
      end
    else # move/copy      
      EOL::Solr::CollectionItemsCoreRebuilder.reindex_collection(collection) unless copy?
      if target_needed?
        collections.each do |target_collection|
          EOL::Solr::CollectionItemsCoreRebuilder.reindex_collection(target_collection)
        end
      end
    end
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
    return @duplicates if defined?(@duplicates)
    @duplicates = []
    collections.each do |target_collection|
      @duplicates +=
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
    @duplicates
  end

  # Returns new collection items in target collection:
  def watch_inserts(&block)
    last_id = CollectionItem.maximum('id')
    yield
    if last_id
      CollectionItem.where(['id > ? AND collection_id IN (?)', last_id, collections.map(&:id)])
    else # Really only useful in tests:
      CollectionItem.where(['collection_id IN (?)', collections.map(&:id)])
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
