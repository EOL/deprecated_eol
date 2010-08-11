class MoveUserPrimaryRoleToUserInfo < ActiveRecord::Migration
  def self.up
    drop_table :user_primary_roles_users
    add_column :user_infos, :user_primary_role_id, :integer
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration.new("Dropping tables that aren't worth rebuilding.  Re-run migrations.")
  end
end
