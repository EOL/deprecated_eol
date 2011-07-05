class AddParentPageIdTocontentPages < ActiveRecord::Migration
  def self.up
    add_column :content_pages, :parent_content_page_id, :int
    add_column :content_page_archives, :parent_content_page_id, :int
  end

  def self.down
    drop_column :content_pages, :parent_content_page_id, :int
    drop_column :content_page_archives, :parent_content_page_id, :int
  end
end
