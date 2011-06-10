class MoveCuratorActivityLogsToLoggingDatabase < ActiveRecord::Migration
  def self.up
    table = CuratorActivityLog.table_name
    CuratorActivityLog.connection.execute("RENAME TABLE `#{ActiveRecord::Base.database_name}`.`#{table}` TO `#{LoggingModel.database_name}`.`#{table}`")
    LoggingModel.connection.execute("ALTER TABLE #{table} ENGINE = MyISAM")
  end

  def self.down
    table = CuratorActivityLog.table_name
    CuratorActivityLog.connection.execute("RENAME TABLE `#{LoggingModel.database_name}`.`#{table}` TO `#{ActiveRecord::Base.database_name}`.`#{table}`")
    ActiveRecord::Base.connection.execute("ALTER TABLE #{table} ENGINE = INNODB")
  end
end
