ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

require 'spec'
require 'spec/rails'
load 'composite_primary_keys/fixtures.rb' 

require File.expand_path(File.dirname(__FILE__) + "/factories")
require File.expand_path(File.dirname(__FILE__) + "/eol_spec_helpers")
require File.expand_path(File.dirname(__FILE__) + "/custom_matchers")

require 'scenarios'
Scenario.load_paths = [ File.join(RAILS_ROOT, 'scenarios') ]

require 'rackbox'

Spec::Runner.configure do |config|
  include Scenario::Spec
  include EOL::Spec::Helpers
  
  truncate_all_tables_once # truncate all tables (once) before running specs

  config.include EOL::Spec::Matchers
  config.use_blackbox = true

  # blackbox specs often use scenarios ... which often make us max out the 
  # primary keys of some of our tables ... reset the auto_incr for these 
  # tables before/after blackbox specs, to try to catch most of these problems
  config.after(:each, :type => :blackbox) do
    reset_auto_increment_on_tables_with_tinyint_primary_keys
  end

  # taken from use_db/lib/override_test_case.rb
  #
  # these before and after blocks make sure that spec 
  # examples run within their own transactions for ALL 
  # active connections (works for ALL of our databases)
  config.before(:each) do

    Rails.cache.clear # This resets all of the in-memory models and other cached items, so we start anew!

    UseDbPlugin.all_use_dbs.collect do |klass|
      klass
    end

    [ User, CuratorActivity, Name ].each do |model|
      conn = model.connection
      Thread.current['open_transactions'] ||= 0
      Thread.current['open_transactions'] += 1
      conn.begin_db_transaction
      # puts "BEGIN transaction"
    end
  end
  config.after(:each) do
    UseDbPlugin.all_use_dbs.collect do |klass|
      klass
    end

    [ User, CuratorActivity, Name ].each do |model|
      conn = model.connection
      conn.rollback_db_transaction
      Thread.current['open_transactions'] = 0
      # puts "ROLLBACK"
      # TODO after rolling back, this might be a good place to reset the auto_increment on tables
    end
  end

end

# quiet down any migrations that run during tests
ActiveRecord::Migration.verbose = false
