class RemoveCreatedAtFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :created_at
  end

  def self.down
    add_column :content_pages, :created_at, :date
  end
end
