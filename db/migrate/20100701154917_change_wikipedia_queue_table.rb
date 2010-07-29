class ChangeWikipediaQueueTable < EOL::DataMigration
  def self.up
    execute('alter table wikipedia_queue add `user_id` int unsigned NOT NULL')
    execute('alter table wikipedia_queue add `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP')
    execute('alter table wikipedia_queue add `harvested_at` timestamp NULL default NULL')
    execute('alter table wikipedia_queue add `harvest_succeeded` tinyint unsigned NULL default NULL')
  end
  
  def self.down
    remove_column :wikipedia_queue, :user_id
    remove_column :wikipedia_queue, :created_at
    remove_column :wikipedia_queue, :harvested_at
    remove_column :wikipedia_queue, :harvest_succeeded
  end
end
