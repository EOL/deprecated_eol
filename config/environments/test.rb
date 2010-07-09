#---------------------------------------------------------------------------------
# Settings specified here will take precedence over those in config/environment.rb
# 1) config/environment.rb
# 2) config/environments/[RAILS_ENV].rb
# 3) config/environments/[RAILS_ENV]_eol_org.rb
# 4) config/environment_eol_org.rb
#---------------------------------------------------------------------------------

# The test environment is used exclusively to run your application's
# test suite.  Otherwise, you never need to work with it.  Remember that
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

$IP_ADDRESS_OF_SERVER='127.0.0.1'

$SOLR_SERVER = 'http://localhost:8983/solr'
$SOLR_DIR    = File.join(RAILS_ROOT, 'solr', 'solr')

config.gem 'faker', :version => "0.3.1"
config.gem "rspec-custom-matchers", :version => "0.1.0", :lib => false
config.gem "remi-indifferent-variable-hash", :version => "0.1.0", :lib => false
config.gem "openrain-scenarios", :version => "0.3.2", :lib => "scenarios"
config.gem "rspec", :version => "1.1.12", :lib => false
config.gem "rspec-rails", :version => "1.1.12", :lib => false
config.gem "thoughtbot-factory_girl", :version => "1.1.5", :lib => false
config.gem "remi-rackbox", :version => "1.1.2", :lib => false
# Note we are using an old version of metric_fu; 1.2 has a dependency on activesupport that we're not using for Rails.
# TODO - when we update our Rails version, update metric_fu
config.gem "metric_fu", :version => '1.1.6', :lib => 'metric_fu'
config.gem "ruby2ruby", :version => "1.2.4"
config.gem "reek", :version => '1.2.8'
