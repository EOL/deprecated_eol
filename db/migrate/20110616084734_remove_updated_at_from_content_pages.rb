class RemoveUpdatedAtFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :updated_at
  end

  def self.down
    add_column :content_pages, :updated_at, :date
  end
end
