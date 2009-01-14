class TaxonConceptNamesIndexNameId < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute "CREATE INDEX name_id ON taxon_concept_names (name_id)"
  end

  def self.down
    remove_index :taxon_concept_names, :name=>'name_id'
  end
end
