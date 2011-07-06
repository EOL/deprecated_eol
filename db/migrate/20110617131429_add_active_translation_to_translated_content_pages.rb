class AddActiveTranslationToTranslatedContentPages < ActiveRecord::Migration
  def self.up
    add_column :translated_content_pages, :active_translation, :tinyint
  end

  def self.down
    remove_column :translated_content_pages, :active_translation
  end
end
