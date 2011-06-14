class RemoveLeftContentFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :left_content
  end

  def self.down
    add_column :content_pages, :left_content, :text
  end
end
