class CreateRandomHierarchyImagesTable < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute('CREATE TABLE `random_hierarchy_images` (
      `id` int(11) NOT NULL auto_increment,
      `data_object_id` int(11) NOT NULL,
      `hierarchy_entry_id` int(11) default NULL,
      `hierarchy_id` int(11) default NULL,
      `taxon_concept_id` int(11) default NULL,
      `name` varchar(255) NOT NULL,
      PRIMARY KEY  (`id`),
      KEY `hierarchy_entry_id` (`hierarchy_entry_id`),
      KEY `hierarchy_id` (`hierarchy_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8')
  end

  def self.down
    drop_table :random_hierarchy_images
  end
end
