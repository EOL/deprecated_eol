class CreateTaxonClassificationsLock < ActiveRecord::Migration
  def self.up
    execute 'CREATE TABLE IF NOT EXISTS `taxon_classifications_locks` (
      `id` int(10) unsigned NOT NULL auto_increment,
      `taxon_concept_id` int(10) unsigned NOT NULL,
      `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
      PRIMARY KEY  (`id`),
      UNIQUE KEY `taxon_concept_id` (`taxon_concept_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8'
  end

  def self.down
    drop_table :taxon_classifications_locks
  end
end
