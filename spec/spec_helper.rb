ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'
load 'composite_primary_keys/fixtures.rb' 
require File.expand_path(File.dirname(__FILE__) + "/factories")

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  # taken from use_db/lib/override_test_case.rb
  #
  # these before and after blocks make sure that spec 
  # examples run within their own transactions for ALL 
  # active connections (works for ALL of our databases)
  config.before(:each) do
    UseDbPlugin.all_use_dbs.collect do |klass|
      klass
    end

    ActiveRecord::Base.active_connections.values.uniq.each do |conn|
      Thread.current['open_transactions'] ||= 0
      Thread.current['open_transactions'] += 1
      conn.begin_db_transaction
    end
  end
  config.after(:each) do
    ActiveRecord::Base.active_connections.values.uniq.each do |conn|                  
      conn.rollback_db_transaction
      Thread.current['open_transactions'] = 0
    end
  end
end

# quite down any migrations that run during tests
ActiveRecord::Migration.verbose = false
