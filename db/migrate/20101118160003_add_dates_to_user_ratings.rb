class AddDatesToUserRatings < ActiveRecord::Migration
  def self.up
    add_column :users_data_objects_ratings, :created_at, :timestamp
    add_column :users_data_objects_ratings, :updated_at, :timestamp
  end

  def self.down
    remove_column :users_data_objects_ratings, :created_at
    remove_column :users_data_objects_ratings, :updated_at
  end
end
