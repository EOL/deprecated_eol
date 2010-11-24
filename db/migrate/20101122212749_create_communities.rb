class CreateCommunities < ActiveRecord::Migration
  def self.up
    create_table :communities do |t|
      t.string :name, :limit => 128
      t.text :description
      t.timestamps
    end
    create_table :members do |t|
      t.integer :user_id
      t.integer :community_id
      t.timestamps
    end
  end

  def self.down
    drop_table :communities
    drop_table :members
  end
end
