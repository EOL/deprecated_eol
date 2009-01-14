class CreateTopUnpublishedImages < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute "DROP TABLE IF EXISTS top_unpublished_images"
    execute "CREATE TABLE `top_unpublished_images` (
      `hierarchy_entry_id` int(10) unsigned NOT NULL,
      `data_object_id` int(10) unsigned NOT NULL,
      `view_order` smallint(5) unsigned NOT NULL,
      PRIMARY KEY  (`hierarchy_entry_id`,`data_object_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
  end

  def self.down
    drop_table :top_unpublished_images
  end
end
