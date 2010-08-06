class AddPageLogTable < EOL::LoggingMigration
  def self.up
    execute("CREATE TABLE `page_view_logs` (
      `id` int(11) NOT NULL auto_increment,
      `user_id` int(11) default NULL,
      `agent_id` int(11) default NULL,
      `taxon_concept_id` int(11) NOT NULL,
      `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
      `updated_at` timestamp NOT NULL default '0000-00-00 00:00:00',
      PRIMARY KEY  (`id`),
      KEY `taxon_concept_id` (`taxon_concept_id`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8")
  end
  
  def self.down
    drop_table :page_view_logs
  end
end
