class AddLogosToCollectionsAndCommunities < ActiveRecord::Migration
  def self.up
    execute('ALTER TABLE collections ADD `logo_cache_url` bigint(20) unsigned default NULL')
    execute('ALTER TABLE communities ADD `logo_cache_url` bigint(20) unsigned default NULL')
  end

  def self.down
    remove_column :collections, :logo_cache_url
    remove_column :communities, :logo_cache_url
  end
end
