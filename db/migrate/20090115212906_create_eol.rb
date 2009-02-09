class CreateEol < ActiveRecord::Migration

  def self.up
    ActiveRecord::Migration.not_okay_in_production
    
    # Basically, I want to throw an error if we're not using MySQL, while at the same time providing the framework
    # for adding other DB support in the future...
    if ActiveRecord::Base.connection.class == ActiveRecord::ConnectionAdapters::MysqlAdapter
      # I was having trouble running the whole thing at once, so I'll break it up by command:
      # Note that this assumes that the file has been DOS-ified.
      IO.readlines("#{RAILS_ROOT}/db/eol.sql").to_s.split(/;\s*[\r\n]+/).each do |cmd|
        if cmd =~ /\w/m # Only run commands with text in them.  :)  A few were "\n\n".
          execute cmd.strip
        end
      end
    else
      raise ActiveRecord::IrreversibleMigration.new("Migration error: Unsupported database for initial schema--this was not written portably.")
    end
  end

  def self.down
    ActiveRecord::Migration.not_okay_in_production
    drop_table "comments"
    drop_table "contact_subjects"
    drop_table "contacts"
    drop_table "content_page_archives"
    drop_table "content_pages"
    drop_table "content_sections"
    drop_table "data_object_data_object_tags"
    drop_table "data_object_tags"
    drop_table "error_logs"
    drop_table "news_items"
    drop_table "open_id_authentication_associations"
    drop_table "open_id_authentication_nonces"
    drop_table "roles"
    drop_table "roles_users"
    drop_table "search_suggestions"
    drop_table "sessions"
    drop_table "survey_responses"
    drop_table "taxon_stats"
    drop_table "unique_visitors"
    drop_table "users"
  end
end
