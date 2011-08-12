class AddHierarchyEntryToCuratorActivityLogs < EOL::LoggingMigration
  def self.up
    add_column :curator_activity_logs, :hierarchy_entry_id, :integer, :null => true
  end

  def self.down
    remove_column :curator_activity_logs, :hierarchy_entry_id
  end
end
