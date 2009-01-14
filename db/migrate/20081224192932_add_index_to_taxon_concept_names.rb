class AddIndexToTaxonConceptNames < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute "CREATE INDEX source_hierarchy_entry_id ON taxon_concept_names (source_hierarchy_entry_id)"
  end

  def self.down
    remove_index :taxon_concept_names, :name=>'source_hierarchy_entry_id'
  end
end
