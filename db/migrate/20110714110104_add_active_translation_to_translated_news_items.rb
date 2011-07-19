class AddActiveTranslationToTranslatedNewsItems < ActiveRecord::Migration
  def self.up
    add_column :translated_news_items, :active_translation, :tinyint
  end

  def self.down
    remove_column :translated_news_items, :active_translation
  end
end
