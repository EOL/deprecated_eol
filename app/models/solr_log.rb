class SolrLog < ActiveRecord::Base
  include EOL::PeerSites

  belongs_to :object, :polymorphic => true

  def self.log_transaction(options={})
    # some records are created in migrations before the migration to create this table had run
    return unless SolrLog.table_exists?
    if options[:solr_log]
      if options[:solr_log].class == SolrLog
        SolrLogStatus.create(:solr_log_id => options[:solr_log].id)
      end
    else
      SolrLog.create(
        :core => options[:core],
        :object_id => options[:object_id],
        :object_type => options[:object_type],
        :action => options[:action])
    end
  end
  
end