class AddGuidToUsersDataObjectsRatings < ActiveRecord::Migration
  def self.up
    execute "alter table users_data_objects_ratings add column data_object_guid varchar(32) character set ascii not null"
    #remove_column :users_data_objects_ratings, :data_object_id
  end

  def self.down
    #add_column :users_data_objects_ratings, :data_object_id, :integer
    remove_column :users_data_objects_ratings, :data_object_guid
  end
end
