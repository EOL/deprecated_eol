class SolrLog < ActiveRecord::Base
  
  def self.log_transaction(solr_core, id, type, action, action_keyword=nil)
    sl = SolrLog.new()
    sl.core = solr_core
    sl.object_id = id
    sl.object_type = type
    sl.action = action
    sl.peer_site_id = $PEER_SITE_ID
    sl.action_keyword = action_keyword
    sl.save
  end
  
end