class AddResourceIdToCollections < EOL::DataMigration

  def self.up
    execute('alter table collections add `resource_id` int NULL default NULL after `agent_id`')
  end

  def self.down
    remove_column :collections, :resource_id
  end
end
