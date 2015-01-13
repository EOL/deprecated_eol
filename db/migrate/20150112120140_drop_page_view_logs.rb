class DropPageViewLogs < EOL::LoggingMigration
  def self.up
    connection.drop_table "page_view_logs"
  end

  def down
  end
end
