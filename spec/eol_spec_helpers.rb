module EOL::Spec
  module Helpers

    # returns a connection for each of our databases, eg: 1 for Data, 1 for Logging ...
    def all_connections
      # use_db lazy-loads its db list, so the classes in logging/ are ignored unless you reference one:
      CuratorActivity.first
      UseDbPlugin.all_use_dbs.map {|db| db.connection }
    end

    # call truncate_all_tables but make sure it only 
    # happens once in the Process
    def truncate_all_tables_once
      unless $truncated_all_tables_once
        $truncated_all_tables_once = true
        print "truncating tables ... "
        truncate_all_tables
        puts "done"
      end
    end

    # truncates all tables in all databases
    def truncate_all_tables options = { }
      # TODO don't do 1 execute for each table!  do 1 execute for each connection!  should be faster
      # puts "truncating all tables"
      options[:verbose] ||= false
      all_connections.each do |conn|
        conn.tables.each   do |table|
          unless table == 'schema_migrations'
            puts "[#{conn.instance_eval { @config[:database] }}].`#{table}`" if options[:verbose]
            conn.execute "TRUNCATE TABLE`#{table}`"
          end
        end
      end
    end

  end
end

class ActiveRecord::Base
  
  # truncate's this model's table
  def self.truncate
    connection.execute "TRUNCATE TABLE #{ table_name }"
  rescue => ex
    puts "#{ self.name }.truncate failed ... does the table exist?  #{ ex }"
  end

end
