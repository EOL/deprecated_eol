module EOL::Spec
  module Helpers

    # returns a connection for each of our databases, eg: 1 for Data, 1 for Logging ...
    def all_connections
      UseDbPlugin.all_use_dbs.map {|db| db.connection }
    end

    # truncates all tables in all databases
    def truncate_all_tables options = { }
      options[:verbose] ||= false
      all_connections.each do |conn|
        conn.tables.each   do |table|
          puts "[#{conn.instance_eval { @config[:database] }}].`#{table}`" if options[:verbose]
          conn.execute "TRUNCATE TABLE`#{table}`"
        end
      end
    end

  end
end

class ActiveRecord::Base
  
  # truncate's this model's table
  def self.truncate
    connection.execute "TRUNCATE TABLE #{ table_name }"
  end

end
