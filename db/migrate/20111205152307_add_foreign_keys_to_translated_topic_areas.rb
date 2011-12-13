class AddForeignKeysToTranslatedTopicAreas < ActiveRecord::Migration
  def self.up
    execute('ALTER TABLE translated_topic_areas ADD `language_id` integer default NULL') 
    execute('ALTER TABLE translated_topic_areas ADD `topic_area_id` integer default NULL')
  end

  def self.down
    remove_column :translated_topic_areas, :language_id
    remove_column :translated_topic_areas, :topic_area_id
  end
end
