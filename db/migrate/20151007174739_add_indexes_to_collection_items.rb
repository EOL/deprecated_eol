class AddIndexesToCollectionItems < ActiveRecord::Migration
  def change
    # This will take a LONG TIME to run in production. Sigh.
    add_index :collection_items, :collection_id # Duh.
    add_index :collection_items, :collected_item_type # Duh.
  end
end
