class AddVettedVisibilityToUsersDataObjects < ActiveRecord::Migration
  def self.up
    add_column :users_data_objects, :vetted_id, :integer  rescue puts "column already added"
    add_column :users_data_objects, :visibility_id, :integer  rescue puts "column already added"
    add_column :users_data_objects, :created_at, :date  rescue puts "column already added"
    add_column :users_data_objects, :updated_at, :date  rescue puts "column already added"
  end

  def self.down
    remove_column :users_data_objects, :vetted_id
    remove_column :users_data_objects, :visibility_id
    remove_column :users_data_objects, :created_at
    remove_column :users_data_objects, :updated_at
  end
end
