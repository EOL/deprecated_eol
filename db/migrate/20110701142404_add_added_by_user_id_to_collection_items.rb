class AddAddedByUserIdToCollectionItems < ActiveRecord::Migration
  def self.up
    execute('ALTER TABLE collection_items ADD `added_by_user_id` int(11) unsigned default NULL')
  end

  def self.down
    remove_column :collection_items, :added_by_user_id
  end
end
