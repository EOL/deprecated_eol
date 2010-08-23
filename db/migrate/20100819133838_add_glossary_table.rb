class AddGlossaryTable < EOL::DataMigration
  def self.up
    execute "CREATE TABLE `glossary_terms` (
      `id` int(11) NOT NULL auto_increment,
      `term` varchar(255) default NULL,
      `definition` text,
      `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
      `updated_at` timestamp NULL default NULL,
      PRIMARY KEY  (`id`),
      UNIQUE KEY `term` (`term`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
  end
  
  def self.down
    drop_table :glossary_terms
  end
end
