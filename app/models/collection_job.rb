# NOTE - assuming #update returns an accurate row_count (it seems to):
class CollectionJob < ActiveRecord::Base

  attr_accessible :all_items, :collection, :command, :finished_at, :item_count, :target_collection, :user

  belongs_to :collection
  belongs_to :target_collection, :class_name => 'Collection'
  belongs_to :user

  has_and_belongs_to_many :collection_items

  validates_presence_of :target_collection_id, :if => :target_needed?

  def self.copy(params = {})
    raise EOL::Exceptions::SecurityViolation unless params[:user] && params[:user].can_edit_collection?(params[:target])
    CollectionJob.validate_create_and_run(params.reverse_merge(:command => 'copy'))
  end

  def self.move(params = {})
    raise EOL::Exceptions::SecurityViolation unless params[:user] && params[:user].can_edit_collection?(params[:target])
    CollectionJob.validate_create_and_run(params.reverse_merge(:command => 'move'))
  end

  def self.remove(params = {})
    CollectionJob.validate_create_and_run(params.reverse_merge(:command => 'remove'))
  end

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
  end

  # NOTE - Sadly, this needs to be public because it's called by the class methods.
  def fail_if_no_scope
    raise EOL::Exceptions::CollectionJobRequiresScope if collection_items.empty? && ! all_items
  end

private

  # NOTE - I *want* this to throw exceptions on any validation errors... though I might change my mind later:
  def self.validate_create_and_run(params = {})
    raise EOL::Exceptions::SecurityViolation unless params[:user] && params[:user].can_edit_collection?(params[:source])
    job = CollectionJob.create!(:collection => params[:source],
                                :command => params[:command],
                                :all_items => params[:all_items],
                                :target_collection => params[:target],
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
    all_items? ? copy_all : copy_some
  end

  def copy_all
    CollectionItem.connection.update(ActiveRecord::Base.sanitize_sql_array([%q{
      INSERT IGNORE INTO collection_items (collection_id, collected_item_id, collected_item_type)
        SELECT ?, collected_item_id, collected_item_type
        FROM collection_items
        WHERE collection_id = ?
    },
    target_collection_id,
    collection_id]))
  end

  def copy_some
    CollectionItem.connection.update(ActiveRecord::Base.sanitize_sql_array([%q{
      INSERT IGNORE INTO collection_items (collection_id, collected_item_id, collected_item_type)
        SELECT ?, collected_item_id, collected_item_type
        FROM collection_items
        WHERE id IN (?)
    },
    target_collection_id,
    collection_item_ids]))
  end

  def move
    all_items? ? move_all : move_some
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

  def remove
    all_items? ? remove_all : remove_some
  end

  def remove_all
    CollectionItem.delete_all(["collection_id = ?", collection_id])
  end

  def remove_some
    CollectionItem.delete_all(["id IN (?)", collection_item_ids])
  end

end
