class RemoveUrlFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :url
    remove_column :content_page_archives, :url
  end

  def self.down
    add_column :content_pages, :url, :string
    add_column :content_page_archives, :url, :string
  end
end
