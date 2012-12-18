class RenameCuratorActivityLogsObjectId < EOL::LoggingMigration
  def up
    rename_column :curator_activity_logs, :object_id, :target_id
  end

  def down
    rename_column :curator_activity_logs, :target_id, :object_id
  end
end
