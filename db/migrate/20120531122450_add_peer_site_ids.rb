class AddPeerSiteIds < ActiveRecord::Migration
  def self.up
    execute 'CREATE TABLE `peer_sites` (
      `id` int unsigned NOT NULL,
      `label` text NULL DEFAULT NULL,
      `content_host_url_prefix` text NULL DEFAULT NULL,
      PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8'
    
    tables_which_need_peer_site_ids.each do |table_name|
      execute "ALTER TABLE #{table_name} ADD peer_site_id INT UNSIGNED NULL DEFAULT NULL AFTER id"
      execute "UPDATE #{table_name} SET peer_site_id = #{$PEER_SITE_ID}"
    end
  end

  def self.down
    tables_which_need_peer_site_ids.each do |table_name|
      remove_column table_name, :peer_site_id
    end
    drop_table :peer_sites
  end
  
  def self.tables_which_need_peer_site_ids
    [ 'collections',
      'collection_items',
      'comments',
      'communities',
      'content_partners',
      'data_objects',
      'members',
      'news_items',
      'resources',
      'users',
      'users_data_objects',
      'users_data_objects_ratings']
  end
end
