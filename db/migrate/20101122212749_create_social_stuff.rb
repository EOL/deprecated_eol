class CreateSocialStuff < ActiveRecord::Migration
  def self.up
    create_table :collections do |t|
      t.string :name
      t.integer :community_id
      t.integer :user_id
      t.integer :special_collection_id
      t.boolean :published
      t.timestamps
    end
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
    create_table :special_collections do |t|
      t.string :name, :limit => 32
    end
    SpecialCollection.create_all
    create_table :collection_items do |t|
      t.string :name
      t.string :object_type, :limit => 32
      t.integer :object_id
      t.integer :collection_id
      t.timestamps
    end
  end

  def self.down
    drop_table :communities
    drop_table :members
    drop_table :collections
    drop_table :special_collections
    drop_table :collection_items
  end
end
