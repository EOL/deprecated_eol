class CreateNewContentCacheTables < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    
    execute "DROP TABLE IF EXISTS hierarchies_content_test"
    execute "CREATE TABLE `hierarchies_content_test` (
      `hierarchy_entry_id` int(10) unsigned NOT NULL,
      `text` tinyint(3) unsigned NOT NULL,
      `text_unpublished` tinyint(3) unsigned NOT NULL,
      `image` tinyint(3) unsigned NOT NULL,
      `image_unpublished` tinyint(3) unsigned NOT NULL,
      `child_image` tinyint(3) unsigned NOT NULL,
      `child_image_unpublished` tinyint(3) unsigned NOT NULL,
      `video` tinyint(3) unsigned NOT NULL,
      `video_unpublished` tinyint(3) unsigned NOT NULL,
      `map` tinyint(3) unsigned NOT NULL,
      `map_unpublished` tinyint(3) unsigned NOT NULL,
      `content_level` tinyint(3) unsigned NOT NULL,
      `image_object_id` int(10) unsigned NOT NULL,
      PRIMARY KEY  (`hierarchy_entry_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    
    execute "DROP TABLE IF EXISTS taxon_concept_content_test"
    execute "CREATE TABLE `taxon_concept_content_test` (
      `taxon_concept_id` int(10) unsigned NOT NULL,
      `text` tinyint(3) unsigned NOT NULL,
      `text_unpublished` tinyint(3) unsigned NOT NULL,
      `image` tinyint(3) unsigned NOT NULL,
      `image_unpublished` tinyint(3) unsigned NOT NULL,
      `child_image` tinyint(3) unsigned NOT NULL,
      `child_image_unpublished` tinyint(3) unsigned NOT NULL,
      `video` tinyint(3) unsigned NOT NULL,
      `video_unpublished` tinyint(3) unsigned NOT NULL,
      `map` tinyint(3) unsigned NOT NULL,
      `map_unpublished` tinyint(3) unsigned NOT NULL,
      `content_level` tinyint(3) unsigned NOT NULL,
      `image_object_id` int(10) unsigned NOT NULL,
      PRIMARY KEY  (`taxon_concept_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
  end

  def self.down
    drop_table :taxon_concept_content_test
    drop_table :hierarchies_content_test
  end
end
