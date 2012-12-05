module EOL
  class LoggingMigration < ActiveRecord::Migration
    def self.connection
      LoggingModel.connection
    end
    @connection = self.connection
  end
end

