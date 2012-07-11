class CreateSolrLogPeerSite < ActiveRecord::Migration
  def self.up
    execute 'CREATE TABLE `solr_log_statuses` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `peer_site_id` int(10) unsigned NOT NULL,
      `solr_log_id` int(10) unsigned NOT NULL,
      `created_at` datetime DEFAULT NULL,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8'
  end

  def self.down
    drop_table :solr_log_statuses
  end
end