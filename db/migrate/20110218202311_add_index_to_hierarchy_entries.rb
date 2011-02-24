class AddIndexToHierarchyEntries < EOL::DataMigration
  def self.up
    execute('create index hierarchy_parent on hierarchy_entries(hierarchy_id, parent_id)')
    remove_index :hierarchy_entries, :name => 'hierarchy_id'
  end
  
  def self.down
    execute('create index hierarchy_id on hierarchy_entries(hierarchy_id)')
    remove_index :hierarchy_entries, :name => 'hierarchy_parent'
  end
end
