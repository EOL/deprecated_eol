class CreateHierarchyEntriesFlattened < EOL::DataMigration
  def self.up
    execute "CREATE TABLE IF NOT EXISTS `hierarchy_entries_flattened` (
      `hierarchy_entry_id` int(10) unsigned NOT NULL,
      `ancestor_id` int(10) unsigned NOT NULL,
      PRIMARY KEY  (`hierarchy_entry_id`,`ancestor_id`),
      KEY `ancestor_id` (`ancestor_id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8"
  end

  def self.down
    drop_table :hierarchy_entries_flattened
  end
end
