class ReplaceHierarchiesResources < EOL::DataMigration
  
  def self.up
    execute('alter table resources add hierarchy_id int unsigned after `notes`')
    execute('create index hierarchy_id on resources (hierarchy_id)')
    execute('update resources r join hierarchies_resources hr on (r.id=hr.resource_id) set r.hierarchy_id=hr.hierarchy_id')
    drop_table :hierarchies_resources
  end
  
  def self.down
    execute('CREATE TABLE `hierarchies_resources` (
      `resource_id` int(10) unsigned NOT NULL,
      `hierarchy_id` int(10) unsigned NOT NULL,
      PRIMARY KEY  (`resource_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8')
    execute('insert into hierarchies_resources (select id, hierarchy_id from resources)')
    remove_column :resources, :hierarchy_id
  end
end
