class CreateFeedDataObjects < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute 'CREATE TABLE IF NOT EXISTS `feed_data_objects` (
                  `taxon_concept_id` int(10) unsigned NOT NULL,
                  `data_object_id` int(10) unsigned NOT NULL,
                  `data_type_id` smallint(5) unsigned NOT NULL,
                  `created_at` timestamp NOT NULL,
                  PRIMARY KEY  (`taxon_concept_id`,`data_object_id`),
                  KEY `data_object_id` (`data_object_id`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8'
  end

  def self.down
    drop_table :feed_data_objects
  end
end
