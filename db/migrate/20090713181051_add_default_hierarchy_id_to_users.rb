class AddDefaultHierarchyIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :default_hierarchy_id, :integer
  end
  
  def self.down
    remove_column :users, :default_hierarchy_id
  end
end
