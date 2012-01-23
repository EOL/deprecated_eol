class AddShowReferencesToCollections < ActiveRecord::Migration
  def self.up
    add_column :collections, :show_references, :boolean, :default => '1'
  end

  def self.down
    remove_column :collections, :show_references
  end
end
