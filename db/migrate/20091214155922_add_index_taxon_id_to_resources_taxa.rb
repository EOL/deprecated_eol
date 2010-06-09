class AddIndexTaxonIdToResourcesTaxa < EOL::DataMigration
  
  def self.up
    execute("create index taxon_id on resources_taxa(taxon_id)")
  end
  
  def self.down
    remove_index :resources_taxa, :name => 'taxon_id'
  end
end
