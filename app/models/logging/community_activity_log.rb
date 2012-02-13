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

  def notify_listeners
    # TODO
  end

end
