module EOL

  module DB

    @@db_defaults = {
      :charset   => ENV['CHARSET']   || 'utf8',
      :collation => ENV['COLLATION'] || 'utf8_general_ci'
    }
    
    def self.all_connections
      connections = [ActiveRecord::Base, LoggingModel]
      connections.map {|c| c.connection}
    end

    def self.clear_temp
      Dir.new('tmp').select {|f| f =~ /\.(sql|yml)$/ }.each do |f|
        File.unlink("tmp/#{f}")
      end
    end

    # TODO - this won't work if the DB wasn't there before the task. That's why #recreate works (and it calls this), but #create
    # doesn't, on it's own. It needs to find the name via the config, not via the models. rewite.
    def self.create
      arb_conf = ActiveRecord::Base.configurations[Rails.env.to_s]
      log_conf = LoggingModel.configurations["#{Rails.env}_logging"]
      ActiveRecord::Base.establish_connection({'database' => ''}.reverse_merge!(arb_conf))
      ActiveRecord::Base.connection.create_database(arb_conf['database'], arb_conf.reverse_merge!(@@db_defaults))
      ActiveRecord::Base.establish_connection(arb_conf)
      LoggingModel.establish_connection({'database' => ''}.reverse_merge!(log_conf))
      LoggingModel.connection.create_database(log_conf['database'], log_conf.reverse_merge!(@@db_defaults))
      LoggingModel.establish_connection(log_conf)
    end

    def self.drop
      raise "This action is ONLY available in the development and test environments." unless
        Rails.env.development? || Rails.env.development_master? || Rails.env.test? || Rails.env.test_master?
      EOL::DB.all_connections.each do |connection|
        connection.drop_database connection.current_database
      end
    end

    def self.recreate
      EOL::DB.drop
      EOL::DB.create
      Rake::Task['scenarios:clear_tmp'].invoke
      Rake::Task['db:migrate'].invoke
    end

    def self.rebuild
      Rake::Task['solr:start'].invoke
      EOL::DB.recreate
      EOL::DB.clear_temp
      # This looks like duplication with #populate, but it skips truncating, since the DBs are fresh.  Faster:
      Rake::Task['solr:start'].invoke
      ENV['NAME'] = 'bootstrap'
      Rake::Task['scenarios:clear_tmp'].invoke
      Rake::Task['scenarios:load'].invoke
      Rake::Task['solr:rebuild_all'].invoke
    end

    def self.populate
      Rake::Task['solr:start'].invoke
      Rake::Task['truncate'].invoke
      ENV['NAME'] = 'bootstrap'
      Rake::Task['scenarios:clear_tmp'].invoke
      Rake::Task['scenarios:load'].invoke
      Rake::Task['solr:rebuild_all'].invoke
    end

    def start_transactions
      EOL::DB.all_connections.each do |conn|
        Thread.current['open_transactions'] ||= 0
        Thread.current['open_transactions'] += 1
        conn.begin_db_transaction
      end
    end

    def commit_transactions
      EOL::DB.all_connections.each do |conn|
        conn.commit_db_transaction
        conn.begin_db_transaction if conn.open_transactions > 0
      end
    end

    def rollback_transactions
      EOL::DB.all_connections.each do |conn|
        conn.rollback_db_transaction
        Thread.current['open_transactions'] = 0
      end
    end

  end

end
