module EOL::Spec
  module Helpers

    # returns a connection for each of our databases, eg: 1 for Data, 1 for Logging ...
    def all_connections
      # use_db lazy-loads its db list, so the classes in logging/ are ignored unless you reference one:
      CuratorActivity.first
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

    # scenarios to load in spec - most useful for loading up the 'foundation' in blackbox specs
    #
    #   scenario  :foo
    #   scenarios :foo, :bar
    #   scenarios :foo, :bar, :before => :all
    #   scenarios :foo, :bar, :before => :each
    #
    # defaults to before each
    #
    def scenario *scenarios
      require 'scenario'
      options = (scenarios.last.is_a?Hash) ? scenarios.pop : { }
      options[:before] ||= :each
      before options[:before] do
        EOL::Scenario.load *scenarios
      end
    end
    alias scenarios scenario

  end
end

class ActiveRecord::Base
  
  # truncate's this model's table
  def self.truncate
    connection.execute "TRUNCATE TABLE #{ table_name }"
  end

end
