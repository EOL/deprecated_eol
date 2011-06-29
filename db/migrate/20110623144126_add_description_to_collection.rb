class AddDescriptionToCollection < ActiveRecord::Migration
  def self.up
    execute('ALTER TABLE collections ADD `description` text default NULL')
  end

  def self.down
    remove_column :collections, :description
  end
end
