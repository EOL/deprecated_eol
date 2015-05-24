class CreateTableCollectionFromLists < ActiveRecord::Migration
  def up
    create_table :collection_from_lists do |t|
      t.integer :collection_id
      t.timestamps
    end
  end

  def down
    drop_table :collection_from_lists
  end
end
