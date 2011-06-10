class MoveCuratorActivityLogsToLoggingDatabase < ActiveRecord::Migration
  def self.up
    table = CuratorActivityLog.table_name
    CuratorActivityLog.connection.execute("RENAME TABLE `#{ActiveRecord::Base.database_name}`.`#{table}` TO `#{LoggingModel.database_name}`.`#{table}`")
  end

  def self.down
    table = CuratorActivityLog.table_name
    CuratorActivityLog.connection.execute("RENAME TABLE `#{LoggingModel.database_name}`.`#{table}` TO `#{ActiveRecord::Base.database_name}`.`#{table}`")
  end
end
