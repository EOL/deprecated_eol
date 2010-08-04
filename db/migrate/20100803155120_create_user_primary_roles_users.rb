class CreateUserPrimaryRolesUsers < ActiveRecord::Migration
  def self.up
    create_table :user_primary_roles_users do |t|
      t.reference :users
      t.reference :user_primary_roles
    end
  end

  def self.down
  end
end
