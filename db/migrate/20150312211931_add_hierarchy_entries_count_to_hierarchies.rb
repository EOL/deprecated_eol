class AddHierarchyEntriesCountToHierarchies < ActiveRecord::Migration

  def self.up
    add_column :hierarchies, :hierarchy_entries_count, :integer, :null => false, :default => 0
  end

  def self.down
    remove_column :hierarchies, :hierarchy_entries_count
  end

end
