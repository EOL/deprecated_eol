class AddOrderToDataObjectsRefs < ActiveRecord::Migration
  def change
    add_column :data_objects_refs, :order, :int
  end
end
