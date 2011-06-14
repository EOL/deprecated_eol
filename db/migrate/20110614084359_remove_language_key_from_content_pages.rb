class RemoveLanguageKeyFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :language_key
    remove_column :content_page_archives, :language_key
  end

  def self.down
    add_column :content_pages, :language_key, :string
    add_column :content_page_archives, :language_key, :string
  end
end
