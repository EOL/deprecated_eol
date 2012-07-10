class SolrLog < ActiveRecord::Base
  
  def self.log_transaction(solr_core, id, type, action, activity_bash=nil)
    sl = SolrLog.new()
    sl.core = solr_core
    sl.object_id = id
    sl.object_type = type
    sl.action = action
    sl.peer_site_id = $PEER_SITE_ID
    sl.save
    
    if (activity_bash)
      sal = SolrActivityLog.new()
      sal.solr_log = sl
      sal.activity_log_unique_key = activity_bash['activity_log_unique_key'] if activity_bash['activity_log_unique_key'] 
      sal.activity_log_type = activity_bash['activity_log_type'] if activity_bash['activity_log_type']
      sal.activity_log_id = activity_bash['activity_log_id'] if activity_bash['activity_log_id']
      sal.action_keyword = activity_bash['action_keyword'] if activity_bash['action_keyword']
      sal.reply_to_id = activity_bash['reply_to_id'] if activity_bash['reply_to_id']
      sal.user_id = activity_bash['user_id'] if activity_bash['user_id']
      sal.date_created = activity_bash['date_created'] if activity_bash['date_created']
      sal.save
    end    
  end
  
end