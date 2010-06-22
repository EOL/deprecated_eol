ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

require 'spec/autorun'
require 'spec/rails'
load 'composite_primary_keys/fixtures.rb' 
require 'csv'

# just enough infrastructure to get 'assert_select' to work
require 'action_controller'
require 'action_controller/assertions/selector_assertions'
include ActionController::Assertions::SelectorAssertions


require "email_spec/helpers"
require "email_spec/matchers"
Spec::Runner.configure do |config|
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)
end


require File.expand_path(File.dirname(__FILE__) + "/factories")
require File.expand_path(File.dirname(__FILE__) + "/eol_spec_helpers")
require File.expand_path(File.dirname(__FILE__) + "/custom_matchers")

require 'eol_scenarios'
EolScenario.load_paths = [ File.join(RAILS_ROOT, 'scenarios') ]

require 'eol_rackbox'

Spec::Runner.configure do |config|
  include EolScenario::Spec
  include EOL::Data # this gives us access to methods that clean up our data (ie: lft/rgt values)
  include EOL::DB   # this gives us access to methods that handle transactions
  include EOL::Spec::Helpers
  
  config.include EOL::Spec::Matchers
  # Once upon a time, we needed this to run blackbox tests.  Now, if this line is in, Contoller (non-rackbox) tests fail.
  # When we removed this line, everything was happy.  When we remove rackbox entirely, *we* will be happy, too.
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
    Rails.cache.clear
    SpeciesSchemaModel.connection.execute("START TRANSACTION #SpeciesSchemaModel")
    SpeciesSchemaModel.connection.increment_open_transactions

  end
  config.after(:each) do
    SpeciesSchemaModel.connection.decrement_open_transactions
    SpeciesSchemaModel.connection.execute("ROLLBACK #SpeciesSchemaModel")
  end

end

# quiet down any migrations that run during tests
ActiveRecord::Migration.verbose = false


def read_test_file(filename)
  csv_obj = CSV.open(File.expand_path(File.dirname("__FILE__") + "../../spec/csv_files/" + filename), "r", "\t")
  field_names = []
  field_name = ''
  csv_obj.each_with_index do |fields, i|
    if i == 0
      field_names = fields
    else
      result = {}
      field_names.each_with_index do |field_name, ii|
        result[field_name] = fields[ii]
      end
      yield(result)
    end
  end
end

module Spec
  module Rails
    module Example
      class FunctionalExampleGroup < ActionController::TestCase
        # All we need to do is keep a couple of methods from using 'request' and instead their local variable @request:
        def params
          @request.parameters
        end
        def session
          @request.session
        end
      end
    end
  end
end
