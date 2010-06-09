class AddAgentIdToTaxonConceptNames < EOL::DataMigration

  def self.up
    add_column :taxon_concept_names, :agent_id, :integer
  end

  def self.down
    remove_column :taxon_concept_names, :agent_id
  end
end
