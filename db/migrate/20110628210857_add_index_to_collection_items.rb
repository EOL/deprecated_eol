class AddIndexToCollectionItems < ActiveRecord::Migration
  def self.up
    add_index :collection_items, [:collection_id, :object_type, :object_id],
      { :unique => true, :name => 'collection_id_object_type_object_id'}
  end

  def self.down
    remove_index :collection_items, :name => 'collection_id_object_type_object_id'
  end
end
