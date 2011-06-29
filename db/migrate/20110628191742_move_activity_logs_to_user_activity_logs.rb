class MoveActivityLogsToUserActivityLogs < EOL::LoggingMigration
  def self.up
    rename_table :activity_logs, :user_activity_logs
  end

  def self.down
    rename_table :user_activity_logs, :activity_logs
  end
end
