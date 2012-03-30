class CommunityActivityLog < LoggingModel

  include EOL::ActivityLogItem

  belongs_to :community
  belongs_to :user       # Who took the action
  belongs_to :activity   # What happened
  belongs_to :member     # ONLY if it affected one
  belongs_to :collection # ONLY if it affected one

  after_create :log_activity_in_solr
  after_create :queue_notifications

  alias :link_to :community # Needed for rendering links; we need to know which association to make the link to

  def log_activity_in_solr
    keyword = self.activity.name('en') rescue nil
    base_index_hash = {
      'activity_log_unique_key' => "CommunityActivityLog_#{id}",
      'activity_log_type' => 'CommunityActivityLog',
      'activity_log_id' => self.id,
      'action_keyword' => keyword,
      'user_id' => self.user_id,
      'date_created' => self.created_at.solr_timestamp }
    EOL::Solr::ActivityLog.index_notifications(base_index_hash, notification_recipient_objects)
  end

  def queue_notifications
    Notification.queue_notifications(notification_recipient_objects, self)
  end

  def notification_recipient_objects
    return @notification_recipients if @notification_recipients
    @notification_recipients = []
    add_recipient_user_making_edit(@notification_recipients)
    add_recipient_community(@notification_recipients)
    add_recipient_managers(@notification_recipients)
    add_recipient_users_watching(@notification_recipients)
    add_recipient_other_community_members(@notification_recipients)
    @notification_recipients
  end

private

  def add_recipient_user_making_edit(recipients)
    # TODO: this is a new notification type - probably for ACTIVITY only
    recipients << { :user => user, :notification_type => :i_modified_a_community,
                    :frequency => NotificationFrequency.never }
  end

  def add_recipient_community(recipients)
    recipients << self.community
  end
  
  def add_recipient_managers(recipients)
    # add users who want to be notified about becoming a manager
    if activity.id == Activity.add_manager.id && member && frequency = member.user.listening_to?(:made_me_a_manager)
      new_manager = member.user
      recipients << { :user => member.user, :notification_type => :made_me_a_manager,
                      :frequency => frequency }
    end
    community.managers_as_users.each do |manager|
      next if activity.id == Activity.add_manager.id && (new_manager && manager.id == new_manager.id)  # the new manager was notified above...
      if activity.id == Activity.add_manager.id
        manager.add_as_recipient_if_listening_to(:new_manager_in_my_community, recipients)
      elsif activity.id == Activity.join.id && frequency = manager.listening_to?(:member_joined_my_community)
        manager.add_as_recipient_if_listening_to(:member_joined_my_community, recipients)
      elsif activity.id == Activity.leave.id && frequency = manager.listening_to?(:member_left_my_community)
        manager.add_as_recipient_if_listening_to(:member_left_my_community, recipients)
      end
    end
  end
  
  def add_recipient_users_watching(recipients)
    self.community.containing_collections.watch.each do |collection|
      collection.users.each do |user|
        user.add_as_recipient_if_listening_to(:changes_to_my_watched_community, recipients)
      end
    end
  end

  # TODO - this is kinda expensive in large groups. :\
  def add_recipient_other_community_members(recipients)
    community.members.map {|m| m.user }.each do |existing_user|
      next if existing_user.id == member_id # You don't need to be notified about YOU joining!
      user.add_as_recipient_if_listening_to(:member_joined_my_watched_community, recipients)
    end
  end
end
