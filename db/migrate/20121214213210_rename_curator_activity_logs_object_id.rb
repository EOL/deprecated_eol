class RenameCuratorActivityLogsObjectId < EOL::LoggingMigration
  def up
    # TODO - why isn't this working? Note, I tried it without the CuratorActivityLog, also without the #connection.
    # CuratorActivityLog.connection.rename_column :curator_activity_logs, :object_id, :target_id
    CuratorActivityLog.connection.execute \
      "ALTER TABLE curator_activity_logs CHANGE object_id target_id int(11) DEFAULT NULL"
  end

  def down
    # CuratorActivityLog.connection.rename_column :curator_activity_logs, :target_id, :object_id
    CuratorActivityLog.connection.execute \
      "ALTER TABLE curator_activity_logs CHANGE target_id object_id int(11) DEFAULT NULL"
  end
end
