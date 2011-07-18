class ChangesForNewSchema < ActiveRecord::Migration
  def self.up
    # DataObjects
    execute "ALTER TABLE `data_objects` ADD `provider_mangaed_id` varchar(255) default NULL AFTER `identifier`,
      ADD `data_subtype_id` smallint(5) unsigned default NULL AFTER `data_type_id`,
      ADD `metadata_language_id` smallint(5) unsigned default NULL AFTER `language_id`,
      ADD `available_at` timestamp NULL default NULL AFTER `updated_at`"
    
    # Agents
    execute "ALTER TABLE `agents` ADD `given_name` varchar(255) default NULL AFTER `full_name`,
      ADD `family_name` varchar(255) default NULL AFTER `given_name`,
      ADD `email` varchar(255) default NULL AFTER `family_name`,
      ADD `project` varchar(255) default NULL AFTER `logo_cache_url`,
      ADD `organization` varchar(255) default NULL AFTER `project`,
      ADD `account_name` varchar(255) default NULL AFTER `organization`,
      ADD `openid` varchar(255) default NULL AFTER `account_name`,
      ADD `yahoo_id` varchar(255) default NULL AFTER `openid`"
    
    # References
    execute "ALTER TABLE `refs` ADD `provider_mangaed_id` varchar(255) default NULL AFTER `full_reference`,
      ADD `authors` varchar(255) default NULL AFTER `provider_mangaed_id`,
      ADD `editors` varchar(255) default NULL AFTER `authors`,
      ADD `publication_created_at` timestamp NULL default NULL AFTER `editors`,
      ADD `title` varchar(255) default NULL AFTER `publication_created_at`,
      ADD `pages` varchar(255) default NULL AFTER `title`,
      ADD `page_start` varchar(50) default NULL AFTER `pages`,
      ADD `page_end` varchar(50) default NULL AFTER `page_start`,
      ADD `volume` varchar(50) default NULL AFTER `page_end`,
      ADD `edition` varchar(50) default NULL AFTER `volume`,
      ADD `publisher` varchar(255) default NULL AFTER `edition`,
      ADD `language_id` smallint(5) unsigned default NULL AFTER `publisher`"
  end

  def self.down
    remove_column :data_objects, :provider_mangaed_id
    remove_column :data_objects, :data_subtype_id
    remove_column :data_objects, :metadata_language_id
    remove_column :data_objects, :available_at
    
    remove_column :agents, :given_name
    remove_column :agents, :family_name
    remove_column :agents, :email
    remove_column :agents, :project
    remove_column :agents, :organization
    remove_column :agents, :account_name
    remove_column :agents, :openid
    remove_column :agents, :yahoo_id
    
    remove_column :refs, :provider_mangaed_id
    remove_column :refs, :authors
    remove_column :refs, :editors
    remove_column :refs, :publication_created_at
    remove_column :refs, :title
    remove_column :refs, :pages
    remove_column :refs, :page_start
    remove_column :refs, :page_end
    remove_column :refs, :volume
    remove_column :refs, :edition
    remove_column :refs, :publisher
    remove_column :refs, :language_id
  end
end
