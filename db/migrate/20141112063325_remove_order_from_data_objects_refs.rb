class RemoveOrderFromDataObjectsRefs < ActiveRecord::Migration
  def up
    remove_column :data_objects_refs, :order
  end

  def down
    add_column :data_objects_refs, :order, :int
  end
end
