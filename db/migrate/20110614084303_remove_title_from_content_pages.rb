class RemoveTitleFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :title
  end

  def self.down
    add_column :content_pages, :title, :string
  end
end
