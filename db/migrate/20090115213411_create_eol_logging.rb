class CreateEolLogging < EOL::LoggingMigration

  def self.up
    ActiveRecord::Migration.raise_error_if_in_production
    # Basically, I want to throw an error if we're not using MySQL, while at the same time providing the framework
    # for adding other DB support in the future...
    if ActiveRecord::Base.connection.class == ActiveRecord::ConnectionAdapters::MysqlAdapter ||
        ActiveRecord::Base.connection.class == ActiveReload::ConnectionProxy  # could be using ActiveReload (Masochism) as we are now in testing
      # I was having trouble running the whole thing at once, so I'll break it up by command:
      # Note that this assumes that the file has been DOS-ified.
      IO.readlines(Rails.root.join('db', "eol_logging.sql")).to_s.split(/;\s*[\r\n]+/).each do |cmd|
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
    ActiveRecord::Migration.raise_error_if_in_production
    drop_table "activities"
    drop_table "api_logs"
    drop_table "collection_activity_logs"
    drop_table "community_activity_logs"
    drop_table "curator_activity_logs"
    drop_table "external_link_logs"
    drop_table "ip_addresses"
    drop_table "page_view_logs"
    drop_table "search_logs"
    drop_table "translated_activities"
    drop_table "user_activity_logs"
  end
end
