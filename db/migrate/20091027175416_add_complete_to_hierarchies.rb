class AddCompleteToHierarchies < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    execute("alter table hierarchies add `complete` tinyint unsigned NULL default 1 after `browsable`")
    execute("alter table hierarchy_entries add `visibility_id` tinyint unsigned NOT NULL default 0 after `published`")
    execute("alter table taxon_concepts add `split_from` int unsigned not NULL after `supercedure_id`")
    
    execute("create index vetted_id on hierarchy_entries (vetted_id)")
    execute("create index visibility_id on hierarchy_entries (visibility_id)")
    execute("create index published on hierarchy_entries (published)")
  end

  def self.down
    remove_column :hierarchies, :complete
    remove_column :hierarchy_entries, :visibility_id
    remove_column :taxon_concepts, :split_from
    
    remove_index :hierarchy_entries, :name => 'published'
    remove_index :hierarchy_entries, :name => 'vetted_id'
  end
end
