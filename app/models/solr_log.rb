class SolrLog < ActiveRecord::Base
  include EOL::PeerSites

  def self.log_transaction(solr_core, id, type, action)
    sl = SolrLog.new()
    sl.core = solr_core
    sl.object_id = id
    sl.object_type = type
    sl.action = action
    sl.save
  end
  
end