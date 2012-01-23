class CreateCollectionItemsRefs < ActiveRecord::Migration
  def self.up
    create_table :collection_items_refs, :id => false do |t|
      t.integer :collection_item_id, :null => false
      t.integer :ref_id, :null => false       
    end
  end

  def self.down
    drop_table :collection_items_refs
  end
end
