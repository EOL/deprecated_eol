class RemoveTitleFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :title
    remove_column :content_page_archives, :title
  end

  def self.down
    add_column :content_pages, :title, :string
    add_column :content_page_archives, :title, :string
  end
end
