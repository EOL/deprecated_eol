# Settings specified here will take precedence over those in config/environment.rb
# 1) config/environment.rb
# 2) config/environments/[RAILS_ENV].rb
# 3) config/environments/[RAILS_ENV]_eol_org.rb
# 4) config/environment_eol_org.rb

# Set the environment for Passenger
ENV['RAILS_ENV'] = 'test'

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Most directly emulate both development and production environments:
# NOT WORKING: config.cache_store = :mem_cache_store

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test
config.cache_store = :memory_store


config.log_level = :debug # :error

$EXCEPTION_NOTIFY=false # set to false to not be notified of exceptions via email in production mode (set email addresses below)
$ENABLE_RECAPTCHA=false # set to true to enable recaptcha on registration and contact us form
$ENABLE_ANALYTICS=false
$SHOW_SURVEYS=false

$IP_ADDRESS_OF_SERVER='127.0.0.1'

config.gem 'faker', :version => "0.3.1"
config.gem "rspec-custom-matchers", :version => "0.1.0", :lib => false
config.gem "remi-indifferent-variable-hash", :version => "0.1.0", :lib => false
config.gem "openrain-scenarios", :version => "0.3.2", :lib => "scenarios"
config.gem "rspec", :version => "1.1.12", :lib => false
config.gem "rspec-rails", :version => "1.1.12", :lib => false
config.gem "thoughtbot-factory_girl", :version => "1.1.5", :lib => false
config.gem "remi-rackbox", :version => "1.1.2", :lib => false

if ENV["METRICS"] == "true"
  # The metric_fu and it's dependencies is not intended to be part of the application's
  # default runtime and therefore should not be checked into the project's source base.
  # 
  # In order to run the metrics on EOL via various Rake tasks, set set METRICS=true
  #
  # i.e. RAILS_ENV=test METRICS=true rake -T eol:quality 
  config.gem 'jscruggs-metric_fu', :version => '1.1.2', :lib => 'metric_fu', :source => 'http://gems.github.com'
  require 'metric_fu' # Is this superfluous?  Not sure.  in a rush.  (TODO)
end
