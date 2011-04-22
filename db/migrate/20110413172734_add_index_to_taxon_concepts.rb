class AddIndexToTaxonConcepts < EOL::DataMigration
  def self.up
    execute('create index concept_published_visible on hierarchy_entries(taxon_concept_id, published, visibility_id)')
  end

  def self.down
    remove_index :hierarchy_entries, :name => 'concept_published_visible'
  end
end
