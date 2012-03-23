class CreatePreferredEntries < ActiveRecord::Migration
  def self.up
    TaxonConcept.connection.execute "CREATE TABLE `taxon_concept_preferred_entries` (
      `id` int(10) unsigned NOT NULL auto_increment,
      `taxon_concept_id` int(10) unsigned NOT NULL,
      `hierarchy_entry_id` int(10) unsigned NOT NULL,
      `updated_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
      PRIMARY KEY  (`id`),
      UNIQUE KEY `taxon_concept_id` (`taxon_concept_id`)
    ) ENGINE=MyISAM AUTO_INCREMENT=3214252 DEFAULT CHARSET=utf8"
  end

  def self.down
    drop_table :taxon_concept_preferred_entries
  end
end
