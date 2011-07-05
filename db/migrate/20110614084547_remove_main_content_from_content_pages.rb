class RemoveMainContentFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :main_content
    remove_column :content_page_archives, :main_content
  end

  def self.down
    add_column :content_pages, :main_content, :text
    add_column :content_page_archives, :main_content, :text
  end
end
