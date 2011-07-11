class AddLogoAttrFieldsToCollections < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE collections ADD `logo_file_name` varchar(255) default NULL AFTER `logo_cache_url`"
    execute "ALTER TABLE collections ADD `logo_content_type` varchar(255) default NULL AFTER `logo_file_name`"
    execute "ALTER TABLE collections ADD `logo_file_size` int(10) unsigned default '0' AFTER `logo_content_type`"
  end

  def self.down
    remove_column :collections, :logo_file_name
    remove_column :collections, :logo_content_type
    remove_column :collections, :logo_file_size
  end
end
