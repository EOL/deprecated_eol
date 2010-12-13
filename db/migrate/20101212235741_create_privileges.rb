class CreatePrivileges < ActiveRecord::Migration
  def self.up
    create_table :privileges do |t|
      t.string :name, :limit => 32
      t.string :sym, :limit => 32
      t.integer :level
      t.string :type, :limit => 12
    end
    create_table :privileges_roles do |t|
      t.integer :privilege_id
      t.integer :role_id
      t.timestamps
    end
    create_table :members_privileges do |t|
      t.integer :member_id
      t.integer :privilege_id
      t.timestamps
    end
    add_column :roles, :community_id, :integer
    add_column :communities, :show_special_privileges, :boolean, :default => false
    Community.create(:name => 'EOL Admins', :description => 'This is a private community for the administrators of EOL only.')
    Community.create(:name => 'EOL Curators',
                     :description => 'This is a community for the management of curator privileges at EOL.')
  end

  def self.down
    drop_table :privileges
    drop_table :privileges_roles
    drop_table :members_privileges
    remove_column :roles, :community_id
    remove_column :communities, :show_special_privileges
    Community.find_by_name('EOL Admins').destroy!
    Community.find_by_name('EOL Curators').destroy!
  end
end
