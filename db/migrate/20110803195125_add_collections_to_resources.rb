class AddCollectionsToResources < ActiveRecord::Migration
  def self.up
    add_column :resources, :collection_id, :integer
    add_column :resources, :preview_collection_id, :integer
    change_column :collections, :published, :boolean, :default => true
  end

  def self.down
    remove_column :resources, :collection_id
    remove_column :resources, :preview_collection_id
    change_column :collections, :published, :boolean, :default => nil
  end
end
 