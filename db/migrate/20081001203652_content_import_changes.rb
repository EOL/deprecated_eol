class ContentImportChanges < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute "ALTER TABLE data_objects MODIFY `guid` varchar(32) character set ascii NOT NULL"
    execute "ALTER TABLE taxa MODIFY `guid` varchar(32) character set ascii NOT NULL"
    
    execute "CREATE TABLE `statuses` (
       `id` smallint(6) unsigned NOT NULL auto_increment,
       `label` varchar(255) NOT NULL,
       PRIMARY KEY  (`id`),
       KEY `label` (`label`)
      ) ENGINE=InnoDB"
    
    execute "  CREATE TABLE `harvest_events` (
       `id` tinyint(3) unsigned NOT NULL auto_increment,
       `resource_id` varchar(100) character set ascii NOT NULL,
       `began_at` timestamp NOT NULL DEFAULT NOW(),
       `completed_at` timestamp NULL,
       `published_at` timestamp NULL,
       PRIMARY KEY  (`id`),
       KEY `resource_id` (`resource_id`)
      ) ENGINE=InnoDB"
    
    execute "CREATE TABLE `data_objects_harvest_events` (
       `harvest_event_id` int(10) unsigned NOT NULL,
       `data_object_id` int(10) unsigned NOT NULL,
       `guid` varchar(32) character set ascii NOT NULL,
       `status_id` tinyint(3) unsigned NOT NULL,
       PRIMARY KEY  (`harvest_event_id`,`data_object_id`)
      ) ENGINE=InnoDB"
    
    execute "CREATE TABLE `harvest_events_taxa` (
       `harvest_event_id` int(10) unsigned NOT NULL,
       `taxon_id` int(10) unsigned NOT NULL,
       `guid` varchar(32) character set ascii NOT NULL,
       `status_id` tinyint(3) unsigned NOT NULL,
       PRIMARY KEY  (`harvest_event_id`,`taxon_id`)
      ) ENGINE=InnoDB"
      
    change_table :taxa do |t|
      t.remove :resource_id
      t.remove :identifier
      t.remove :source_url
      t.remove :taxon_created_at
      t.remove :taxon_modified_at
    end
    
    execute "CREATE TABLE `resources_taxa` (
        `resource_id` int(10) unsigned NOT NULL,
        `taxon_id` int(10) unsigned NOT NULL,
        `identifier` varchar(255) character set ascii NOT NULL,
        `source_url` varchar(255) character set ascii NOT NULL,
        `taxon_created_at` timestamp NOT NULL default '0000-00-00 00:00:00',
        `taxon_modified_at` timestamp NOT NULL default '0000-00-00 00:00:00',
        PRIMARY KEY  (`resource_id`,`taxon_id`)
      ) ENGINE=InnoDB"
    
    
  end
  
  def self.down
    
    drop_table :resources_taxa
    
    execute "ALTER TABLE taxa ADD COLUMN `resource_id` int(10) unsigned NOT NULL AFTER id"
    execute "ALTER TABLE taxa ADD COLUMN `identifier` varchar(255) character set ascii NOT NULL AFTER resource_id"
    execute "ALTER TABLE taxa ADD COLUMN `source_url` varchar(255) character set ascii NOT NULL AFTER guid"
    execute "ALTER TABLE taxa ADD COLUMN `taxon_created_at` timestamp NOT NULL default '0000-00-00 00:00:00' AFTER name_id"
    execute "ALTER TABLE taxa ADD COLUMN `taxon_modified_at` timestamp NOT NULL default '0000-00-00 00:00:00' AFTER taxon_created_at"
    
    drop_table :harvest_events_taxa
    drop_table :data_objects_harvest_events
    drop_table :harvest_events
    drop_table :statuses
    execute "ALTER TABLE taxa MODIFY `guid` varchar(20) character set ascii NOT NULL"
    execute "ALTER TABLE data_objects MODIFY `guid` varchar(20) character set ascii NOT NULL"
  end
end
