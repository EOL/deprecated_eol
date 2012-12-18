class RenameCuratorActivityLogsObjectId < EOL::LoggingMigration
  def up
    connection.rename_column :curator_activity_logs, :object_id, :target_id
  end

  def down
    connection.rename_column :curator_activity_logs, :target_id, :object_id
  end
end
