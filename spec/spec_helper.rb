# NOTE - This really really really needs to be at the very tippity-top of the file.  Leave it here.
require 'simplecov'
SimpleCov.start do
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Libraries", "lib"
  add_group "Helpers", "app/helpers"
  add_group "Requests", "requests"
  # TODO - really, we should be testing these. ...But for now, I'm excluding them because many are one-offs:
  add_filter "/initializers/"
  # TODO - really, we should be testing these too, but we want to re-write them. They are ancient:
  add_filter "/administrator/"
  add_filter "controllers/admins/"
  add_filter "spec/"
end

ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rspec'
require 'webmock/rspec'
# TODO - use config to allow: Rails.configuration.the_host_names_for_those_two
WebMock.disable_net_connect!(:allow_localhost => true) # Selenium and Virtuoso.

require 'email_spec'
require 'eol_scenarios'
EolScenario.load_paths = [ Rails.root.join('scenarios') ]

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# quiet down any migrations that run during tests
ActiveRecord::Migration.verbose = false
Rails.logger.level = 4
RSpec.configure do |config|
  include TruncateHelpers # ...We want to truncate the tables once here.

  Solr.start

  config.include FactoryGirl::Syntax::Methods

  config.use_transactional_fixtures = false

  # It's a complex project, so, yeah, we have a LOT of helpers:
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)
  config.include(Helpers) # Global helpers for all specs.
  config.include(TruncateHelpers) # Used quite often to clear database. TODO - replace this with database_cleaner
  config.include(VirtuosoHelpers) # Used often to clear triple store.
  config.include(ScenarioHelpers) # Of course, this is used to load scenarios nicely.
  config.include(OauthHelpers) # Of course, this is used to load scenarios nicely. # TODO - only one spec uses these methods
                               # outside of controller specs, so restrivt this to controller specs and move/change that spec.
                               # spec/lib/eol/open_auth_spec.rb use #stub_oauth_requests
  config.include(EOL::Builders) # Used to build taxa, data objects, etc.

  truncate_all_tables_once

  # Hmmn. We really want to clear the entire cache before EVERY test?  Okay...  :\
  config.after(:each) do
    Rails.cache.clear if Rails.cache
    I18n.locale = :en
    # TODO - make this method directly available in specs
    ClassVariableHelper.clear_class_variables
  end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # NOTE - errr... this doesn't appear to be working, which is a shame. It would be handy!
  config.after(:each, :type => :feature) do
    if example.exception
      artifact = save_page
      puts "\n\"#{example.description}\" failed. Page saved to #{artifact}"
    end
  end

  config.after(:suite) do
    Solr.stop
  end
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
