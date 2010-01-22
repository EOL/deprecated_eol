class DropNormalizedNamesTables < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute "drop table normalized_names"
    execute "drop table normalized_links"
    execute "drop table normalized_qualifiers"
    execute "drop table random_taxa"
  end
  
  def self.down
    execute "CREATE TABLE `normalized_names` (
      `id` int(10) unsigned NOT NULL auto_increment,
      `name_part` varchar(100) NOT NULL,
      PRIMARY KEY  (`id`),
      KEY `name_part` (`name_part`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    
    execute "CREATE TABLE `normalized_links` (
      `normalized_name_id` int(10) unsigned NOT NULL,
      `name_id` int(10) unsigned NOT NULL,
      `seq` tinyint(3) unsigned NOT NULL,
      `normalized_qualifier_id` tinyint(3) unsigned NOT NULL,
      PRIMARY KEY  (`normalized_name_id`,`name_id`),
      KEY `name_id` (`name_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    
    execute "CREATE TABLE `normalized_qualifiers` (
      `id` smallint(5) unsigned NOT NULL auto_increment,
      `label` varchar(50) NOT NULL,
      PRIMARY KEY  (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
    
    execute "CREATE TABLE `random_taxa` (
      `id` int(11) NOT NULL auto_increment,
      `language_id` int(11) NOT NULL,
      `data_object_id` int(11) NOT NULL,
      `name_id` int(11) NOT NULL,
      `image_url` varchar(255) character set ascii NOT NULL,
      `thumb_url` varchar(255) character set ascii NOT NULL,
      `name` varchar(255) NOT NULL,
      `common_name_en` varchar(255) NOT NULL,
      `common_name_fr` varchar(255) NOT NULL,
      `content_level` int(11) NOT NULL,
      `created_at` timestamp NOT NULL default CURRENT_TIMESTAMP,
      `taxon_concept_id` int(11) default NULL,
      PRIMARY KEY  (`id`),
      KEY `index_random_taxa_on_content_level` (`content_level`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8"
  end
end
