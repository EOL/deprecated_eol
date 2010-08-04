class CreateUserPrimaryRoles < ActiveRecord::Migration
  def self.up
    create_table :user_primary_roles do |t|
      t.string :name, :limit => 64
    end
  end

  def self.down
    drop_table :user_primary_roles
  end
end
