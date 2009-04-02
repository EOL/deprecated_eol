class CuratorDatoRatings < ActiveRecord::Migration
  def self.up
    create_table :users_data_objects_ratings do |t|
      t.integer :user_id
      t.integer :data_object_id
      t.integer :rating
    end
  end

  def self.down
    drop_table :users_data_objects_ratings
  end
end
