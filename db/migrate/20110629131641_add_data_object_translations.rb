class AddDataObjectTranslations < ActiveRecord::Migration
  def self.up
    execute 'CREATE TABLE `data_object_translations` (
      `id` int unsigned NOT NULL auto_increment,
      `data_object_id` int unsigned NOT NULL,
      `original_data_object_id` int unsigned NOT NULL,
      `language_id` smallint unsigned NOT NULL,
      `created_at` datetime default NULL,
      `updated_at` datetime default NULL,
      PRIMARY KEY  (`id`),
      UNIQUE KEY `data_object_id` (`data_object_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8'
  end

  def self.down
    drop_table :data_object_translations
  end
end
