class CollectionActivityLog < LoggingModel

  include EOL::ActivityLogItem

  belongs_to :collection, :touch => true
  belongs_to :collection_item # ONLY if it affected one
  belongs_to :user # Who took the action
  belongs_to :activity # What happened

  after_create :log_activity_in_solr
  after_create :queue_notifications

  alias :link_to :collection # Needed for rendering links; we need to know which association to make the link to

  def log_activity_in_solr
    if self.collection_item && self.collection_item.collection
      return if self.collection_item.collection.watch_collection?
    end
    keyword = self.collection_item.object_type rescue nil
    base_index_hash = {
      'activity_log_unique_key' => "CollectionActivityLog_#{id}",
      'activity_log_type' => 'CollectionActivityLog',
      'activity_log_id' => self.id,
      'action_keyword' => keyword,
      'user_id' => self.user_id,
      'date_created' => self.created_at.solr_timestamp }
    EOL::Solr::ActivityLog.index_notifications(base_index_hash, notification_recipient_objects)
    SolrLog.log_transaction($SOLR_ACTIVITY_LOGS_CORE, self.id, 'CollectionActivityLog', 'update')
  end
  
  def queue_notifications
    Notification.queue_notifications(notification_recipient_objects, self)
  end

  def notification_recipient_objects
    return @notification_recipients if @notification_recipients
    @notification_recipients = []
    add_recipient_collection(@notification_recipients)
    add_recipient_communities(@notification_recipients)
    add_recipient_containing_collections(@notification_recipients)
    add_recipient_collector(@notification_recipients)
    add_recipient_users_watchlists(@notification_recipients)
    add_recipient_users_getting_watched(@notification_recipients)
    @notification_recipients
  end

private

  def add_recipient_collection(recipients)
    recipients << self.collection  # for collection newsfeed
  end

  def add_recipient_collector(recipients)
    # TODO: this is a new notification type - probably for ACTIVITY only
    recipients << { :user => user, :notification_type => :i_collected_something,
                    :frequency => NotificationFrequency.never }
  end

  def add_recipient_communities(recipients)
    if self.collection && ! self.collection.communities.blank?
      recipients += self.collection.communities  # communities associated this collection
    end
  end

  def add_recipient_containing_collections(recipients)
    # news feed of collections which contain the thing commented on
    Collection.which_contain(self.collection).each do |c|
      recipients << c
    end
  end

  def add_recipient_users_watchlists(recipients)
    recipients.select{ |c| c.class == Collection && c.watch_collection? }.each do |collection|
      collection.users.each do |user|
        user.add_as_recipient_if_listening_to(:changes_to_my_watched_collection, recipients)
      end
    end
  end

  def add_recipient_users_getting_watched(recipients)
    if someone_is_being_watched?
      collection_item.object.add_as_recipient_if_listening_to(:i_am_being_watched, recipients)
    end
  end

  def someone_is_being_watched?
    activity.id == Activity.collect.id && collection_item && collection_item.object_type == 'User'
  end

end
