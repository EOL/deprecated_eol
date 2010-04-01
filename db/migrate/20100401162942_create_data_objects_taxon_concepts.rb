class CreateDataObjectsTaxonConcepts < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute 'CREATE TABLE IF NOT EXISTS `data_objects_taxon_concepts` (
                `taxon_concept_id` int(10) unsigned NOT NULL,
                `data_object_id` int(10) unsigned NOT NULL,
                PRIMARY KEY  (`taxon_concept_id`,`data_object_id`),
                KEY `data_object_id` (`data_object_id`)
              ) ENGINE=InnoDB DEFAULT CHARSET=utf8'
  end
  
  def self.down
    drop_table :data_objects_taxon_concepts
  end
end
