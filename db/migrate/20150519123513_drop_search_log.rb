class DropSearchLog  < EOL::LoggingMigration
  def self.up
    connection.drop_table :search_logs
  end
end
