class SolrLogStatus < ActiveRecord::Base
  include EOL::PeerSites

  belongs_to :solr_log

end