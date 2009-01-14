class CreateTaxonConceptTables < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    
    execute "DROP TABLE IF EXISTS taxon_concept_content"
    execute "CREATE TABLE `taxon_concept_content` (
      `taxon_concept_id` int(10) unsigned NOT NULL,
      `text` tinyint(3) unsigned NOT NULL,
      `image` tinyint(3) unsigned NOT NULL,
      `child_image` tinyint(3) unsigned NOT NULL,
      `flash` tinyint(3) unsigned NOT NULL,
      `youtube` tinyint(3) unsigned NOT NULL,
      `internal_image` tinyint(3) unsigned NOT NULL,
      `gbif_image` tinyint(3) unsigned NOT NULL,
      `content_level` tinyint(3) unsigned NOT NULL,
      `image_object_id` int(10) unsigned NOT NULL,
      PRIMARY KEY  (`taxon_concept_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    
    execute "DROP TABLE IF EXISTS hierarchy_entry_relationships"
    execute "CREATE TABLE `hierarchy_entry_relationships` (
      `hierarchy_entry_id_1` int(10) unsigned NOT NULL,
      `hierarchy_entry_id_2` int(10) unsigned NOT NULL,
      `relationship` varchar(30) NOT NULL,
      `score` double NOT NULL,
      `extra` text NOT NULL,
      PRIMARY KEY  (`hierarchy_entry_id_1`,`hierarchy_entry_id_2`),
      KEY `score` (`score`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    
    execute "DROP TABLE IF EXISTS taxon_concept_relationships"
    execute "CREATE TABLE `taxon_concept_relationships` (
      `taxon_concept_id_1` int(10) unsigned NOT NULL,
      `taxon_concept_id_2` int(10) unsigned NOT NULL,
      `relationship` varchar(30) NOT NULL,
      `score` double NOT NULL,
      `extra` text NOT NULL,
      PRIMARY KEY  (`taxon_concept_id_1`,`taxon_concept_id_2`),
      KEY `score` (`score`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    
    execute "DROP TABLE IF EXISTS hierarchies_resources"
    execute "CREATE TABLE `hierarchies_resources` (
      `resource_id` int(10) unsigned NOT NULL,
      `hierarchy_id` int(10) unsigned NOT NULL,
      PRIMARY KEY  (`resource_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    
    execute "ALTER TABLE resources ADD COLUMN notes TEXT DEFAULT NULL AFTER vetted"
    execute "ALTER TABLE taxa ADD COLUMN hierarchy_entry_id INT UNSIGNED NOT NULL AFTER name_id"
    execute "ALTER TABLE hierarchies ADD COLUMN agent_id INT UNSIGNED NOT NULL AFTER id"
    
    execute "ALTER TABLE data_objects MODIFY object_cache_url BIGINT UNSIGNED DEFAULT NULL"
    execute "ALTER TABLE data_objects MODIFY thumbnail_cache_url BIGINT UNSIGNED DEFAULT NULL"
    execute "ALTER TABLE table_of_contents MODIFY view_order SMALLINT UNSIGNED DEFAULT 0"
    execute "ALTER TABLE hierarchy_entries MODIFY identifier VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL"
    
    execute "CREATE INDEX parent_name_id ON name_languages (parent_name_id)"
    
  end

  def self.down
    
    remove_index :name_languages, :name=>'parent_name_id'
    
    execute "ALTER TABLE hierarchy_entries MODIFY identifier VARCHAR(20) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL"
    execute "ALTER TABLE table_of_contents MODIFY view_order TINYINT NOT NULL"
    execute "ALTER TABLE data_objects MODIFY thumbnail_cache_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL" 
    execute "ALTER TABLE data_objects MODIFY object_cache_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL" 
    
    remove_column :hierarchies, :agent_id
    remove_column :taxa, :hierarchy_entry_id
    remove_column :resources, :notes
    
    drop_table :hierarchies_resources
    drop_table :taxon_concept_relationships
    drop_table :hierarchy_entry_relationships
    drop_table :taxon_concept_content
    
  end
end
