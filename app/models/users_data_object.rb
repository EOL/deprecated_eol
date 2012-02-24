class UsersDataObject < ActiveRecord::Base

  include EOL::ActivityLogItem
  include EOL::CuratableAssociation

  validates_presence_of :user_id, :data_object_id
  validates_uniqueness_of :data_object_id

  belongs_to :user
  belongs_to :data_object
  belongs_to :taxon_concept
  belongs_to :vetted
  belongs_to :visibility

  named_scope :notifications_not_prepared, :conditions => "notifications_prepared_at IS NULL"

  after_create :queue_notifications

  def self.get_user_submitted_data_object_ids(user_id)
    if(user_id == 'All') then
      sql="Select data_object_id From users_data_objects"
      rset = UsersDataObject.find_by_sql([sql])
    else
      sql="Select data_object_id From users_data_objects where user_id = ? "
      rset = UsersDataObject.find_by_sql([sql, user_id])
    end
    obj_ids = Array.new
    rset.each do |rec|
      obj_ids << rec.data_object_id
    end
    return obj_ids
  end

  # The only thing we care about, really, is people who are watching the TC where this UDO was created:
  def notify_listeners
    taxon_concept.containing_collections.watch.each do |collection|
      collection.users.each do |user|
        user.notify_if_listening(:to => :new_data_on_my_watched_item, :about => self)
      end
    end
  end

private

  def queue_notifications
    Resque.enqueue(PrepareAndSendNotifications)
  end

end
