class RemoveUnusedTables < EOL::DataMigration
  def self.up
    drop_table :hierarchy_entry_names
    drop_table :taxon_concept_relationships
    drop_table :mappings
  end

  def self.down
    execute "
      CREATE TABLE `hierarchy_entry_names` (
        `hierarchy_entry_id` int(10) unsigned NOT NULL,
        `italics` varchar(300) NOT NULL,
        `italics_canonical` varchar(300) NOT NULL,
        `normal` varchar(300) NOT NULL,
        `normal_canonical` varchar(300) NOT NULL,
        `common_name_en` varchar(300) NOT NULL,
        `common_name_fr` varchar(300) NOT NULL,
        PRIMARY KEY  (`hierarchy_entry_id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    
    execute "
      CREATE TABLE `taxon_concept_relationships` (
        `taxon_concept_id_1` int(10) unsigned NOT NULL,
        `taxon_concept_id_2` int(10) unsigned NOT NULL,
        `relationship` varchar(30) NOT NULL,
        `score` double NOT NULL,
        `extra` text NOT NULL,
        PRIMARY KEY  (`taxon_concept_id_1`,`taxon_concept_id_2`),
        KEY `score` (`score`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    
    execute "
      CREATE TABLE `mappings` (
        `id` int(10) unsigned NOT NULL auto_increment,
        `collection_id` mediumint(8) unsigned NOT NULL,
        `name_id` int(10) unsigned NOT NULL,
        `foreign_key` varchar(600) character set ascii NOT NULL,
        PRIMARY KEY  (`id`),
        KEY `name_id` (`name_id`),
        KEY `collection_id` (`collection_id`),
        KEY `collection_id_name_id` (`collection_id`,`name_id`)
      ) ENGINE=InnoDB AUTO_INCREMENT=27739059 DEFAULT CHARSET=utf8"
  end
end
