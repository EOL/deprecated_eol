class CreateSolrLogs < ActiveRecord::Migration
  def self.up
    execute 'CREATE TABLE `solr_logs` (
      `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
      `peer_site_id` int(10) unsigned NOT NULL,
      `core` varchar(255) NOT NULL,
      `object_id` int(10) unsigned NULL default NULL,
      `object_type` varchar(255) NULL default NULL,
      `action` varchar(255) NULL default NULL,
      `created_at` datetime DEFAULT NULL,
      `updated_at` datetime DEFAULT NULL,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8'
  end

  def self.down
    drop_table :solr_logs
  end
end
