class CommunityActivityLog < LoggingModel

  include EOL::ActivityLogItem

  belongs_to :community
  belongs_to :user       # Who took the action
  belongs_to :activity   # What happened
  belongs_to :member     # ONLY if it affected one
  belongs_to :collection # ONLY if it affected one

  named_scope :notifications_not_prepared, :conditions => "notifications_prepared_at IS NULL"

  after_create :log_activity_in_solr
  after_create :queue_notifications

  def log_activity_in_solr
    keyword = self.activity.name('en') rescue nil
    base_index_hash = {
      'activity_log_unique_key' => "CommunityActivityLog_#{id}",
      'activity_log_type' => 'CommunityActivityLog',
      'activity_log_id' => self.id,
      'action_keyword' => keyword,
      'user_id' => self.user_id,
      'date_created' => self.created_at.solr_timestamp }
    EOL::Solr::ActivityLog.index_activities(base_index_hash, activity_logs_affected)
  end

  def activity_logs_affected
    logs_affected = {}
    # activity feed of user making comment
    logs_affected['User'] = [ self.user_id ]
    # activity feed of community that was edited
    logs_affected['Community'] = [ self.community_id ]
    logs_affected
  end

  # Note you can pass in #find options, here, so, for example, you might specify :select => 'id'.
  def models_affected(options = {})
    affected = []
    log_hash = activity_logs_affected
    original_options = options.dup # For whatever reason (I didn't want to dig), options gets modified in the #find,
                                   # below.  To avoid this, we dup the original options, then...
    log_hash.keys.each do |klass_name|
      options = original_options.dup # ...here we make sure the options we pass in are a dupe of the originals.
      # A little ruby magic to turn the string into an actual class, then #find the instances for each...
      affected += Kernel.const_get(klass_name).find(log_hash[klass_name], options)
    end
    affected
  end

  def notify_listeners
    if activity.id == Activity.add_manager.id
      # You have been made a collection or community manager
      new_manager = member.user
      PendingNotification.if_listening(new_manager, :to => :made_me_a_manager, :about => self)
      # Another member has become a manager of a community you manage
      community.managers_as_users.each do |manager|
        next if manager.id == new_manager.id # They were notified above...
        manager.notify_if_listening(:to => :new_manager_in_my_community, :about => self)
      end
    elsif activity.id == Activity.join.id
      # A new member has joined a community that you manage
      community.managers_as_users.each do |manager|
        manager.notify_if_listening(:to => :member_joined_my_community, :about => self)
      end
      # New members have joined a community where you are a member TODO - this is kinda expensive in large groups. :\
      community.members.map {|m| m.user }.each do |old_member|
        next if old_member.id == member_id # You don't need to be notified about YOU joining!
        old_member.notify_if_listening(:to => :member_joined_my_watched_community, :about => self)
      end
    elsif activity.id == Activity.leave.id
      # Members have left a community you manage
      community.managers_as_users.each do |manager|
        manager.notify_if_listening(:to => :member_left_my_community, :about => self)
      end
    end
    # Changes to communities in your watchlist
    models_affected(:select => 'id').each do |object|
      object.respond_to?(:containing_collections)
      object.containing_collections.watch.each do |collection|
        # NOTE - this is assuming that there is only one user in #users, since it's a watch list:
        user = collection.users.first
        user.notify_if_listening(:to => :changes_to_my_watched_community, :about => self)
      end
    end
  end

private

  def queue_notifications
    Resque.enqueue(PrepareAndSendNotifications)
  end

end
