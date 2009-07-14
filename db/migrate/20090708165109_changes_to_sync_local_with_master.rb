class ChangesToSyncLocalWithMaster < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    add_index :data_objects_taxa, :identifier, :name => 'identifier'
    add_index :harvest_events_taxa, :taxon_id, :name => 'taxon_id'
    add_index :mappings, :collection_id, :name => 'collection_id'
    add_index :refs, :full_reference, :name => 'full_reference'
    add_index :resources_taxa, :identifier, :name => 'identifier'
    add_index :synonyms, :name_id, :name => 'name_id'
    add_index :taxon_concepts, :supercedure_id, :name => 'supercedure_id'
    add_index :taxon_concepts, :published, :name => 'published'    
    
    remove_column :hierarchy_entries, :remote_id
    execute('alter table harvest_events modify `id` int(10) unsigned NOT NULL auto_increment')
  end
  
  def self.down
    remove_index :data_objects_taxa, :name => :identifier
    remove_index :harvest_events_taxa, :name => :taxon_id
    remove_index :mappings, :name => :collection_id
    remove_index :refs, :name => :full_reference
    remove_index :resources_taxa, :name => :identifier
    remove_index :synonyms, :name => :name_id
    remove_index :taxon_concepts, :name => :supercedure_id
    remove_index :taxon_concepts, :name => :published
    
    
    execute('alter table hierarchy_entries add `remote_id` varchar(255) character set ascii NOT NULL after `identifier`')
    execute('alter table harvest_events modify `id` int(10) unsigned NOT NULL auto_increment')
  end
end
