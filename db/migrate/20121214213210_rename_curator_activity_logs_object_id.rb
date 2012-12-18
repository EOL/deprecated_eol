class RenameCuratorActivityLogsObjectId < EOL::LoggingMigration
  def up
    CuratorActivityLog.connection.rename_column :curator_activity_logs, :object_id, :target_id
  end

  def down
    CuratorActivityLog.connection.rename_column :curator_activity_logs, :target_id, :object_id
  end
end
