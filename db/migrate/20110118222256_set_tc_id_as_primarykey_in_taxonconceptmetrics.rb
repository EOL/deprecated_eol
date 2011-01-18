class SetTcIdAsPrimarykeyInTaxonconceptmetrics < EOL::DataMigration
  def self.up
    execute "ALTER TABLE `taxon_concept_metrics` ADD PRIMARY KEY (taxon_concept_id)"    
  end

  def self.down
    execute "ALTER TABLE `taxon_concept_metrics` DROP PRIMARY KEY"
  end
end
