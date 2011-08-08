class AddVettedVisibilityToUsersDataObjects < ActiveRecord::Migration
  def self.up
    add_column :users_data_objects, :vetted_id, :integer
    add_column :users_data_objects, :visibility_id, :integer
    add_column :users_data_objects, :created_at, :date
    add_column :users_data_objects, :updated_at, :date
  end

  def self.down
    remove_column :users_data_objects, :vetted_id
    remove_column :users_data_objects, :visibility_id
    remove_column :users_data_objects, :created_at
    remove_column :users_data_objects, :updated_at
  end
end
