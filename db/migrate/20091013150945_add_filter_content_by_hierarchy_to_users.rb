class AddFilterContentByHierarchyToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :filter_content_by_hierarchy, :boolean, :default => false
  end

  def self.down
    remove_column :users, :filter_content_by_hierarchy
  end
end
