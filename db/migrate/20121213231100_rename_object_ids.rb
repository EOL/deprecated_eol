class RenameCollectionItemObjectId < ActiveRecord::Migration
  def up
    rename_column :collection_items, :object_id, :collected_item_id
    rename_column :collection_items, :object_type, :collected_item_type
    rename_column :curator_activity_logs, :object_id, :target_id
    rename_column :curator_activity_logs, :object_type, :target_type
  end

  def down
    rename_column :collection_items, :collected_item_id, :object_id
    rename_column :collection_items, :collected_item_type, :object_type
    rename_column :curator_activity_logs, :target_id, :object_id
    rename_column :curator_activity_logs, :target_type, :object_type
  end
end
