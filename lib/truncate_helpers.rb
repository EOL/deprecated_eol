# Methods to assist in the truncation of tables for specs, scenarios, and other administrative tasks. Probably not
# wise to use this in production.
#
# Note this is a module that should be INCLUDED. These aren't class methods.
module TruncateHelpers

  # call truncate_all_tables but make sure it only happens once in the Process
  # TODO - why?  Any spec that needs truncated tables should probably truncate tables. (Most do.) Smells of a hack.
  def truncate_all_tables_once
    unless $truncated_all_tables_once
      $truncated_all_tables_once = true
      print "truncating tables ... "
      truncate_all_tables
      puts "done"
    end
  end

  # truncates all tables in all databases
  def truncate_all_tables(options = {})
    options[:skip_empty_tables] = true unless options[:skip_empty_tables] === false
    options[:verbose] ||= false
    EOL::Db.all_connections.uniq.each do |conn|
      count = 0
      conn.tables.each do |table|
        next if table == 'schema_migrations'
        count += 1
        if conn.respond_to? :with_master
          conn.with_master do
            truncate_table(conn, table, options[:skip_empty_tables])
          end
        else
          truncate_table(conn, table, options[:skip_empty_tables])
        end
      end
      puts "-- Truncated #{count} tables in #{conn.instance_eval { @config[:database] }}." if options[:verbose]
    end
    Rails.cache.clear if Rails.cache
    ClassVariableHelper.clear_class_variables
  end

  def truncate_table(conn, table, skip_if_empty)
    run_command = if skip_if_empty
      result = conn.execute("SELECT SQL_NO_CACHE 1 FROM #{table} LIMIT 1")
      result.first
    end
    conn.execute "TRUNCATE TABLE `#{table}`" if run_command
  end

end
