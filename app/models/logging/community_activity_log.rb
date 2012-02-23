class CommunityActivityLog < LoggingModel

  include EOL::ActivityLogItem

  belongs_to :community
  belongs_to :user       # Who took the action
  belongs_to :activity   # What happened
  belongs_to :member     # ONLY if it affected one
  belongs_to :collection # ONLY if it affected one

  named_scope :notifications_not_prepared, :conditions => "notifications_prepared_at IS NULL"

  after_create :log_activity_in_solr

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
    log_hash.keys.each do |klass_name|
      # A little ruby magic to turn the string into an actual class, then #find the instances for each...
      affected += Kernel.const_get(klass_name).find(log_hash[klass_name], options)
    end
    affected
  end

    # Community:
    Activity.find_or_create('create')
    Activity.find_or_create('delete')
    Activity.find_or_create('add_member')
    Activity.find_or_create('add_collection')
    Activity.find_or_create('change_description')
    Activity.find_or_create('change_name')
    Activity.find_or_create('change_icon')
    Activity.find_or_create('add_manager')
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
    elsif activity.id == Activity.add_member.id
      # A new member has joined a community that you manage
      community.managers_as_users.each do |manager|
        manager.notify_if_listening(:to => :member_joined_my_community, :about => self)
      end
      # New members have joined a community where you are a member TODO - this is kinda expensive in large groups. :\
      members.map {|m| m.user }.each do |old_member|
        next if old_member.id == member_id # You don't need to be notified about YOU joining!
        old_member.notify_if_listening(:to => :member_joined_my_watched_community, :about => self)
      end
    end
    # Changes to communities in your watchlist
    # Members have left a community you manage
  end

end
