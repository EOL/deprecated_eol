class CreateCuratedPreferredEntries < ActiveRecord::Migration
  def self.up
    execute 'CREATE TABLE IF NOT EXISTS `curated_taxon_concept_preferred_entries` (
      `id` int(10) unsigned NOT NULL auto_increment,
      `taxon_concept_id` int(10) unsigned NOT NULL,
      `hierarchy_entry_id` int(10) unsigned NOT NULL,
      `user_id` int(10) unsigned default NULL,
      `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
      PRIMARY KEY  (`id`),
      UNIQUE KEY `taxon_concept_id` (`taxon_concept_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8'
  end

  def self.down
    drop_table :curated_taxon_concept_preferred_entries
  end
end
