class AddBioToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :bio, :text
  end

  def self.down
    remove_column :users, :bio
  end
end
