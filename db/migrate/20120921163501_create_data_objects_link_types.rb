class CreateDataObjectsLinkTypes < ActiveRecord::Migration
  def self.up
    execute 'CREATE TABLE `data_objects_link_types` (
      `data_object_id` int(10) unsigned NOT NULL,
      `link_type_id` int(10) unsigned NOT NULL,
      PRIMARY KEY (`data_object_id`),
      KEY `data_type_id` (`link_type_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8'
  end

  def self.down
    drop_table :data_objects_link_types
  end
end
