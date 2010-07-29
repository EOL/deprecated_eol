class AddHierarchyEntryStats < EOL::DataMigration
  def self.up
    execute('CREATE TABLE `hierarchy_entry_stats` (
      `hierarchy_entry_id` int unsigned NOT NULL,
      `text_trusted` mediumint unsigned NOT NULL,
      `text_untrusted` mediumint unsigned NOT NULL,
      `image_trusted` mediumint unsigned NOT NULL,
      `image_untrusted` mediumint unsigned NOT NULL,
      `bhl` mediumint unsigned NOT NULL,
      `all_text_trusted` mediumint unsigned NOT NULL,
      `all_text_untrusted` mediumint unsigned NOT NULL,
      `all_image_trusted` mediumint unsigned NOT NULL,
      `all_image_untrusted` mediumint unsigned NOT NULL,
      `all_bhl` int unsigned NOT NULL,
      PRIMARY KEY  (`hierarchy_entry_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8')
    
    execute('CREATE TABLE `taxon_concept_stats` (
      `taxon_concept_id` int unsigned NOT NULL,
      `text_trusted` mediumint unsigned NOT NULL,
      `text_untrusted` mediumint unsigned NOT NULL,
      `image_trusted` mediumint unsigned NOT NULL,
      `image_untrusted` mediumint unsigned NOT NULL,
      `bhl` mediumint unsigned NOT NULL,
      PRIMARY KEY  (`taxon_concept_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8')
  end

  def self.down
    drop_table :hierarchy_entry_stats
    drop_table :taxon_concept_stats
  end
end
