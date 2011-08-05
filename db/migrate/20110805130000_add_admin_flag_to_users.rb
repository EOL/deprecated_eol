class AddAdminFlagToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :admin, :boolean, :default => nil
  end

  def self.down
    remove_column :users, :admin
  end
end
