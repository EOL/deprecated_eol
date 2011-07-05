class RemoveLeftContentFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :left_content
    remove_column :content_page_archives, :left_content
  end

  def self.down
    add_column :content_pages, :left_content, :text
    add_column :content_page_archives, :left_content, :text
  end
end
