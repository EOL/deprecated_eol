class RemoveRolesAndPrivs < ActiveRecord::Migration
  def self.up
    add_column :members, :manager, :boolean, :default => nil
    drop_table :privileges
    drop_table :translated_privileges rescue nil # Doesn't exist in migrations anymore
    drop_table :member_privileges
    drop_table :members_roles
    drop_table :privileges_roles
    remove_column :roles, :community_id
    remove_column :communities, :show_special_privileges
  end

  # NOTE this creates empty stupid tables (just an id) simply to make migration reversible.  Clearly, you can't use
  # them.  :)
  def self.down
    add_column :communities, :show_special_privileges
    add_column :roles, :community_id
    create_table :privileges_roles do |t|
      #don't care
    end
    create_table :members_roles do |t|
      #don't care
    end
    create_table :member_privileges do |t|
      #don't care
    end
    create_table :translated_privileges do |t|
      #don't care
    end
    create_table :privileges do |t|
      #don't care
    end
    remove_column :members, :manager
  end
end
