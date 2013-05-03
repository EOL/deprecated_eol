# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

require Rails.root.join('spec', 'eol_spec_helpers')
require Rails.root.join('spec', 'custom_matchers')

require 'email_spec'
require 'eol_scenarios'
EolScenario.load_paths = [ Rails.root.join('scenarios') ]

require 'eol_data'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# quiet down any migrations that run during tests
ActiveRecord::Migration.verbose = false

RSpec.configure do |config|
  include EOL::Data # this gives us access to methods that clean up our data (ie: lft/rgt values)
  include EOL::DB   # this gives us access to methods that handle transactions
  include EOL::RSpec::Helpers

  config.include FactoryGirl::Syntax::Methods

  config.use_transactional_fixtures = false

  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)
  config.include(Capybara, :type => :integration)

  truncate_all_tables_once

  # Hmmn. We really want to clear the entire cache before EVERY test?  Okay...  :\
  config.after(:each) do
    Rails.cache.clear if Rails.cache
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234        ( or --order rand:1234 )
  # Or run in in the order they are declared in the file with
  #     --order default
  config.order = "random"
end

def wait_for_insert_delayed(&block)
  countdown = 10
  begin
    yield
    return
  rescue RSpec::Expectations::ExpectationNotMetError => e
    countdown -= 1
    sleep(0.2)
    retry if countdown > 0
    raise e
  end
end

def read_test_file(filename)
  csv_obj = CSV.read(Rails.root.join("spec", "csv_files", filename))
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

module RSpec
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
