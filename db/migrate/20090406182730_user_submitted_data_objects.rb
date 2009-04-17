class UserSubmittedDataObjects < ActiveRecord::Migration
  def self.up
    create_table :users_data_objects do |t|
      t.integer :user_id
      t.integer :data_object_id
    end
  end

  def self.down
    drop_table :users_data_objects
  end
end
