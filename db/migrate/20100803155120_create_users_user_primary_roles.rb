class CreateUsersUserPrimaryRoles < ActiveRecord::Migration
  def self.up
    create_table :users_user_primary_roles do |t|
      t.reference :users
      t.reference :user_primary_roles
    end
  end

  def self.down
  end
end
