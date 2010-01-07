class RemoveAgentIdFromTaxonConceptNamesAndAddSynonymId < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  # The previous migration should have run in production without having created any "orphan" agents, so we are not using any
  # logic to find agents associated with TCNs and replace them with Synonyms.  This MIGHT cause a problem in your development
  # setting, but it shouldn't be disasterous.  ;)
  def self.up
    remove_column :taxon_concept_names, :agent_id
    add_column :taxon_concept_names, :synonym_id, :integer
  end

  def self.down
    remove_column :taxon_concept_names, :synonym_id
    add_column :taxon_concept_names, :agent_id, :integer
  end
end
