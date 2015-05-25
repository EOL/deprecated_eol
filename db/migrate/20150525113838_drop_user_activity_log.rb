class DropUserActivityLog < EOL::LoggingMigration
  
  def self.up
    connection.drop_table :user_activity_logs
  end
end
