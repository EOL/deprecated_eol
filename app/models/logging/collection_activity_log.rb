class CollectionActivityLog < LoggingModel

  include EOL::ActivityLogItem

  belongs_to :collection
  belongs_to :collection_item # ONLY if it affected one
  belongs_to :user # Who took the action
  belongs_to :activity # What happened

  named_scope :notifications_not_prepared, :conditions => "notifications_prepared_at IS NULL"

  after_create :log_activity_in_solr

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
    # TODO
  end

end
