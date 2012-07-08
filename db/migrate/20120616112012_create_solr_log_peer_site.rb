class CreateSolrLogPeerSite < ActiveRecord::Migration
  def self.up
    create_table :solr_logs_site_peers do |t|
      t.integer :solr_log_id
      t.integer :peer_site_id
      t.timestamps
    end    
  end

  def self.down
    drop_table :solr_logs_site_peers
  end
end