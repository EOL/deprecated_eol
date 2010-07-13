class AlterHierarchyEntryStats < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute('alter table hierarchy_entry_stats add `total_children` int unsigned NOT NULL')
  end
  
  def self.down
    remove_column :hierarchy_entry_stats, :total_children
  end
end
