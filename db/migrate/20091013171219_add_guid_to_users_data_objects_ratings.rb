class AddGuidToUsersDataObjectsRatings < ActiveRecord::Migration
  def self.up
    add_column :users_data_objects_ratings, :data_object_guid, :string, :limit => 32
  end

  def self.down
    remove_column :users_data_objects_ratings, :data_object_guid
  end
end
