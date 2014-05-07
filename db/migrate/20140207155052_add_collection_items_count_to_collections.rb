class AddCollectionItemsCountToCollections < ActiveRecord::Migration

  def self.up

    add_column :collections, :collection_items_count, :integer, :null => false, :default => 0
    CollectionItem.counter_culture_fix_counts

  end

  def self.down

    remove_column :collections, :collection_items_count

  end

end
