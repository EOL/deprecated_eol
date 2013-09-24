class RenameCollectionItemObjectId < ActiveRecord::Migration
  def self.up
    rename_column :collection_items, :object_id, :collected_item_id
    rename_column :collection_items, :object_type, :collected_item_type
  end

  def self.down
    rename_column :collection_items, :collected_item_id, :object_id
    rename_column :collection_items, :collected_item_type, :object_type
  end
end
