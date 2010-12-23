class CreatePrivileges < ActiveRecord::Migration

  def self.up

    create_table :privileges do |t|
      t.string :name, :limit => 32
      t.string :sym, :limit => 32
      t.integer :level
      t.boolean :special, :default => false
    end

    create_table :member_privileges do |t|
      t.integer :member_id
      t.integer :privilege_id
      t.boolean :revoked, :default => false
      t.timestamps
    end

    create_table :members_roles, :id => false do |t|
      t.integer :member_id
      t.integer :role_id
    end
    add_index :members_roles, [:member_id, :role_id]

    create_table :privileges_roles, :id => false do |t|
      t.integer :privilege_id
      t.integer :role_id
      t.timestamps
    end
    add_index :privileges_roles, [:privilege_id, :role_id]

    add_column :roles, :community_id, :integer

    # This makes me want to cry, but boolean DID NOT WORK here... You could NEVER change the value to non-false.  Worked fine
    # on privileges.  Not here.  I don't know wht, and it's very, very frustrating, and I was done trying to figure out the
    # problem.
    add_column :communities, :show_special_privileges, :integer, :default => 0

  end

  def self.down
    drop_table :privileges
    drop_table :member_privileges
    drop_table :members_roles
    drop_table :privileges_roles
    remove_column :roles, :community_id
    remove_column :communities, :show_special_privileges
  end

end
