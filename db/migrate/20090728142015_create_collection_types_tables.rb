class CreateCollectionTypesTables < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    execute('CREATE TABLE `collection_types` (
      `id` smallint UNSIGNED NOT NULL auto_increment,
      `parent_id` int(11) NOT NULL,
      `lft` smallint UNSIGNED NULL default NULL,
      `rgt` smallint UNSIGNED NULL default NULL,
      `label` varchar(300) NOT NULL,
      PRIMARY KEY  (`id`),
      KEY `parent_id` (`parent_id`),
      KEY `lft` (`lft`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8')
    
    execute('CREATE TABLE `collection_types_collections` (
      `collection_type_id` smallint UNSIGNED NOT NULL,
      `collection_id` mediumint UNSIGNED NOT NULL,
      PRIMARY KEY  (`collection_type_id`, `collection_id`),
      KEY `collection_id` (`collection_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8')
  end

  def self.down
    drop_table :collection_types
    drop_table :collection_types_collections
  end
end