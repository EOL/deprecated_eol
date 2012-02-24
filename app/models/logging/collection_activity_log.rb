class CollectionActivityLog < LoggingModel

  include EOL::ActivityLogItem

  belongs_to :collection
  belongs_to :collection_item # ONLY if it affected one
  belongs_to :user # Who took the action
  belongs_to :activity # What happened

  named_scope :notifications_not_prepared, :conditions => "notifications_prepared_at IS NULL"

  after_create :log_activity_in_solr
  after_create :queue_notifications

  def log_activity_in_solr
    keyword = self.collection_item.object_type rescue nil
    base_index_hash = {
      'activity_log_unique_key' => "CollectionActivityLog_#{id}",
      'activity_log_type' => 'CollectionActivityLog',
      'activity_log_id' => self.id,
      'action_keyword' => keyword,
      'user_id' => self.user_id,
      'date_created' => self.created_at.solr_timestamp }
    EOL::Solr::ActivityLog.index_activities(base_index_hash, activity_logs_affected)
  end

  def activity_logs_affected
    logs_affected = {}
    # activity feed of user making comment
    logs_affected['User'] = [ self.user.id ]
    logs_affected['Collection'] = [ self.collection.id ]
    if self.collection && ! self.collection.communities.blank?
      logs_affected['Community'] = [ self.collection.communities ]
    end
    # news feed of collections which contain the thing commented on
    Collection.which_contain(self.collection).each do |c|
      logs_affected['Collection'] ||= []
      logs_affected['Collection'] << c.id
    end
    logs_affected
  end

  def notify_listeners
    notify_watchers_about_changes
    notify_watched_user
  end

private

  def notify_watchers_about_changes
    Collection.find(activity_logs_affected['Collection']).select {|c| c.watch_collection? }.each do |collection|
      collection.users.each do |user|
        user.notify_if_listening(:to => :changes_to_my_watched_collection, :about => self)
      end
    end
  end

  def notify_watched_user
    if someone_is_being_watched?
      collection_item.object.notify_if_listening(:to => :i_am_being_watched, :about => self)
    end
  end

  def someone_is_being_watched?
    activity.id == Activity.collect.id && collection_item.object_type == 'User'
  end

  def queue_notifications
    Resque.enqueue(PrepareAndSendNotifications)
  end

end
