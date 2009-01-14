class RemoveAdminUsers < ActiveRecord::Migration
  def self.up
    drop_table :admin_users
  end

  def self.down
  end
end
