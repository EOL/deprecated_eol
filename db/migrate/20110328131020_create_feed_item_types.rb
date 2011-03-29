class CreateFeedItemTypes < ActiveRecord::Migration
  def self.up
    create_table :feed_item_types do |t|
      t.string :name, :limit => 32
      t.timestamps
    end
    add_column :feed_items, :feed_item_type_id, :integer, :default => 0
  end

  def self.down
    remove_column :feed_items, :feed_item_type_id
    drop_table :feed_item_types
  end
end
