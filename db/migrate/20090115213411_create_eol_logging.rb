class CreateEolLogging < ActiveRecord::Migration
  def self.database_model
    return "LoggingModel"
  end

  def self.up
    ActiveRecord::Migration.not_okay_in_production
    # Basically, I want to throw an error if we're not using MySQL, while at the same time providing the framework
    # for adding other DB support in the future...
    if ActiveRecord::Base.connection.class == ActiveRecord::ConnectionAdapters::MysqlAdapter
      # I was having trouble running the whole thing at once, so I'll break it up by command:
      # Note that this assumes that the file has been DOS-ified.
      IO.readlines("#{RAILS_ROOT}/db/eol_logging.sql").to_s.split(/;\s*[\r\n]+/).each do |cmd|
        if cmd =~ /\w/m # Only run commands with text in them.  :)  A few were "\n\n".
          execute cmd.strip
        end
      end
    else
      # Perhaps not the right error class to throw, but I'm not aware of good alternatives:
      raise ActiveRecord::IrreversibleMigration.new("Migration error: Unsupported database for initial schema--this was not written portably.")
    end
  end

  def self.down
    ActiveRecord::Migration.not_okay_in_production
    drop_table "agent_log_dailies"
    drop_table "country_log_dailies"
    drop_table "curator_activities"
    drop_table "curator_activity_log_dailies"
    drop_table "curator_comment_logs"
    drop_table "curator_data_object_logs"
    drop_table "data_object_log_dailies"
    drop_table "data_object_logs"
    drop_table "external_link_logs"
    drop_table "ip_addresses"
    drop_table "search_logs"
    drop_table "state_log_dailies"
    drop_table "user_log_dailies"
  end
end
