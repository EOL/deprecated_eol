class AddSomeNeededIndices < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    add_index :taxon_concepts, :published, :name => 'published'    
    add_index :mappings, :collection_id, :name => 'collection_id'    
  end
  
  def self.down
    remove_index :taxon_concepts, :name => :published
    remove_index :mappings, :name => :collection_id
  end
end
