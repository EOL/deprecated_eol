class AgentsAddLogoCacheUrl < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  def self.up
    execute "ALTER TABLE agents ADD COLUMN logo_cache_url BIGINT UNSIGNED DEFAULT NULL AFTER logo_url"
    
  end

  def self.down
    remove_column :agents, :logo_cache_url
  end
end
