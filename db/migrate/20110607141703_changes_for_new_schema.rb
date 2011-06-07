class ChangesForNewSchema < ActiveRecord::Migration
  def self.up
    # DataObjects
    execute "ALTER TABLE `data_objects` ADD `provider_mangaed_id` varchar(255) default NULL AFTER `identifier`"
    execute "ALTER TABLE `data_objects` ADD `data_subtype_id` smallint(5) unsigned default NULL AFTER `data_type_id`"
    execute "ALTER TABLE `data_objects` ADD `metadata_language_id` smallint(5) unsigned default NULL AFTER `language_id`"
    execute "ALTER TABLE `data_objects` ADD `available_at` timestamp NULL default NULL AFTER `updated_at`"
    
    # Agents
    execute "ALTER TABLE `agents` ADD `given_name` varchar(255) default NULL AFTER `full_name`"
    execute "ALTER TABLE `agents` ADD `family_name` varchar(255) default NULL AFTER `given_name`"
    execute "ALTER TABLE `agents` ADD `email` varchar(255) default NULL AFTER `family_name`"
    execute "ALTER TABLE `agents` ADD `project` varchar(255) default NULL AFTER `logo_cache_url`"
    execute "ALTER TABLE `agents` ADD `organization` varchar(255) default NULL AFTER `project`"
    execute "ALTER TABLE `agents` ADD `account_name` varchar(255) default NULL AFTER `organization`"
    execute "ALTER TABLE `agents` ADD `openid` varchar(255) default NULL AFTER `account_name`"
    execute "ALTER TABLE `agents` ADD `yahoo_id` varchar(255) default NULL AFTER `openid`"
    
    # References
    execute "ALTER TABLE `refs` ADD `provider_mangaed_id` varchar(255) default NULL AFTER `full_reference`"
    execute "ALTER TABLE `refs` ADD `authors` varchar(255) default NULL AFTER `provider_mangaed_id`"
    execute "ALTER TABLE `refs` ADD `editors` varchar(255) default NULL AFTER `authors`"
    execute "ALTER TABLE `refs` ADD `publication_created_at` timestamp NULL default NULL AFTER `editors`"
    execute "ALTER TABLE `refs` ADD `title` varchar(255) default NULL AFTER `publication_created_at`"
    execute "ALTER TABLE `refs` ADD `pages` varchar(255) default NULL AFTER `title`"
    execute "ALTER TABLE `refs` ADD `page_start` varchar(50) default NULL AFTER `pages`"
    execute "ALTER TABLE `refs` ADD `page_end` varchar(50) default NULL AFTER `page_start`"
    execute "ALTER TABLE `refs` ADD `volume` varchar(50) default NULL AFTER `page_end`"
    execute "ALTER TABLE `refs` ADD `edition` varchar(50) default NULL AFTER `volume`"
    execute "ALTER TABLE `refs` ADD `publisher` varchar(255) default NULL AFTER `edition`"
    execute "ALTER TABLE `refs` ADD `language_id` smallint(5) unsigned default NULL AFTER `publisher`"
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
