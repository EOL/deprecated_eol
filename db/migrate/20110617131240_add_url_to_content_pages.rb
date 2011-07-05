class AddUrlToContentPages < ActiveRecord::Migration
  def self.up
    add_column :content_pages, :url, :string
  end

  def self.down
    remove_column :content_pages, :url
  end
end
