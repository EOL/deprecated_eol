class CreateListItems < ActiveRecord::Migration
  def self.up
    create_table :list_items do |t|
      t.string :name
      t.string :object_type, :limit => 32
      t.integer :object_id
      t.integer :list_id
      t.timestamps
    end
  end

  def self.down
    drop_table :list_items
  end
end
