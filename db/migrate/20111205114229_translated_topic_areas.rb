class TranslatedTopicAreas < ActiveRecord::Migration
  def self.up
    execute 'CREATE TABLE `translated_topic_areas` (
      `id` int unsigned NOT NULL auto_increment,
      `topic_area_id` int unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `label` varchar(255) default NULL,
      `translated_created_at` datetime default NULL,
      `translated_updated_at` datetime default NULL,
      PRIMARY KEY  (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8'
  end

  def self.down
    drop_table :translated_topic_areas
  end
end
