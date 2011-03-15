class CreateTaxonConceptsFlattened < EOL::DataMigration
  def self.up
    execute "CREATE TABLE IF NOT EXISTS `taxon_concepts_flattened` (
      `taxon_concept_id` int(10) unsigned NOT NULL,
      `ancestor_id` int(10) unsigned NOT NULL,
      PRIMARY KEY  (`taxon_concept_id`,`ancestor_id`),
      KEY `ancestor_id` (`ancestor_id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8"
  end

  def self.down
    drop_table :taxon_concepts_flattened
  end
end
