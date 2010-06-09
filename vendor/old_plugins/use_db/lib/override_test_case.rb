# puts "Overriding Test::Unit::TestCase"

module Test #:nodoc:
  module Unit #:nodoc:
    class TestCase #:nodoc:
      #alias_method :rails_setup_with_fixtures, :setup_with_fixtures
      
      def setup_with_fixtures
        return unless defined?(ActiveRecord::Base) && !ActiveRecord::Base.configurations.blank?
        
        if pre_loaded_fixtures && !use_transactional_fixtures
          raise RuntimeError, 'pre_loaded_fixtures requires use_transactional_fixtures' 
        end

        @fixture_cache = Hash.new

        # Load fixtures once and begin transaction.
        if use_transactional_fixtures?
          # puts "Using transactional fixtures" 
          if @@already_loaded_fixtures[self.class]
            @loaded_fixtures = @@already_loaded_fixtures[self.class]
          else
            load_fixtures
            @@already_loaded_fixtures[self.class] = @loaded_fixtures
          end
          
          UseDbPlugin.all_use_dbs.collect do |klass|
            klass
          end

          # puts "Establishing TRANSACTION for #{ActiveRecord::Base.active_connections.values.uniq.length} open connections"

          ActiveRecord::Base.active_connections.values.uniq.each do |conn|
            # puts "BEGIN on #{klass_name}: #{Thread.current['open_transactions']}"
            Thread.current['open_transactions'] ||= 0
            Thread.current['open_transactions'] += 1
            conn.begin_db_transaction
          end
          
        # Load fixtures for every test.
        else
          # puts "NOT Using transactional fixtures: #{self.use_transactional_fixtures}"
          @@already_loaded_fixtures[self.class] = nil
          load_fixtures
        end

        # Instantiate fixtures for every test if requested.
        if use_instantiated_fixtures
          # puts "Instantiating fixtures for #{self.class}"
          instantiate_fixtures 
        else
          # puts "Not instantiating fixtures"
        end
      end

      #alias_method :rails_teardown_with_fixtures, :teardown_with_fixtures

      def teardown_with_fixtures        
        # puts "Finshing TRANSACTION for #{ActiveRecord::Base.active_connections.values.uniq.length} open connections"

        return unless defined?(ActiveRecord::Base) && !ActiveRecord::Base.configurations.blank?

        # Rollback changes if a transaction is active        
        ActiveRecord::Base.active_connections.values.uniq.each do |conn|                  
          if use_transactional_fixtures?
            conn.rollback_db_transaction
            Thread.current['open_transactions'] = 0
          end
          
          # klass.verify_active_connections!          
        end
      end
      
      def self.uses_db?
        return true
      end      
    end
  end
end