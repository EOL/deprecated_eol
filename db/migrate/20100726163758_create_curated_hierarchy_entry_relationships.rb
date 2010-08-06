class CreateCuratedHierarchyEntryRelationships < EOL::DataMigration
  def self.up
    execute("CREATE TABLE `curated_hierarchy_entry_relationships` (
      `hierarchy_entry_id_1` int unsigned NOT NULL,
      `hierarchy_entry_id_2` int unsigned NOT NULL,
      `user_id` int unsigned NULL,
      `equivalent` tinyint unsigned NOT NULL,
      PRIMARY KEY  (`hierarchy_entry_id_1`,`hierarchy_entry_id_2`),
      KEY `hierarchy_entry_id_2` (`hierarchy_entry_id_2`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8")
  end
  
  def self.down
    drop_table :curated_hierarchy_entry_relationships
  end
end
