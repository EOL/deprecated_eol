class CreateImageCrops < ActiveRecord::Migration
  def self.up
    create_table :image_crops do |t|
      t.column :data_object_id, 'integer unsigned', :null => false
      t.column :user_id, 'integer unsigned', :null => false
      t.column :original_object_cache_url, 'bigint unsigned', :null => false
      t.column :new_object_cache_url, 'bigint unsigned', :null => false
      t.timestamps
    end
    add_index :image_crops, :data_object_id, :name => 'data_object_id'
  end

  def self.down
    drop_table :image_crops
  end
end
