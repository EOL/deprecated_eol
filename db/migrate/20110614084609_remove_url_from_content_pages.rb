class RemoveUrlFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :url
  end

  def self.down
    add_column :content_pages, :url, :string
  end
end
