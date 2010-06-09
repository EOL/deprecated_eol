class ChangeLogsToMyisam < EOL::LoggingMigration

  def self.up
    LoggingModel.connection.tables.each do |table_name|
      LoggingModel.connection.execute("ALTER TABLE #{table_name} ENGINE = MyISAM")
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration.new(
      'We just changed your tables to MyISAM, this is not something that should be undone.'
    )
  end

end
