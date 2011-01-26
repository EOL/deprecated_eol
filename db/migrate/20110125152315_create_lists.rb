class CreateLists < ActiveRecord::Migration
  def self.up
    create_table :lists do |t|
      t.string :name
      t.integer :community_id
      t.integer :user_id
      t.integer :special_list_id
      t.boolean :published
      t.timestamps
    end
  end

  def self.down
    drop_table :lists
  end
end
