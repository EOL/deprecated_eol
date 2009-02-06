ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

require 'spec'
require 'spec/rails'
load 'composite_primary_keys/fixtures.rb' 

require File.expand_path(File.dirname(__FILE__) + "/factories")
require File.expand_path(File.dirname(__FILE__) + "/eol_spec_helpers")
require File.expand_path(File.dirname(__FILE__) + "/custom_matchers")

require 'scenarios'
Scenario.load_paths = [ File.join(RAILS_ROOT, 'scenarios'), File.join(RAILS_ROOT, 'spec', 'scenarios') ]

require 'rackbox'

Spec::Runner.configure do |config|
  include Scenario::Spec
  include EOL::Spec::Helpers

  config.include EOL::Spec::Matchers

  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.use_blackbox               = true
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

  # this is expensive so we should run it once before running 
  # the *whole* suite, not once per spec ... putting it here for now, tho
  config.before(:all) do
    truncate_all_tables
  end

end

# quiet down any migrations that run during tests
ActiveRecord::Migration.verbose = false
