class RemoveUrlFromTranslatedContentPages < ActiveRecord::Migration
  def self.up
    remove_column :translated_content_pages, :url
  end

  def self.down
    add_column :translated_content_pages, :url, :string
  end
end
