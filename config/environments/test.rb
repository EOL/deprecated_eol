#---------------------------------------------------------------------------------
# Settings specified here will take precedence over those in config/environment.rb
# 1) config/environment.rb
# 2) config/environments/[Rails.env].rb
# 3) config/environments/[Rails.env]_eol_org.rb
# 4) config/environment_eol_org.rb
#---------------------------------------------------------------------------------
require 'ruby-debug'

# The test environment is used exclusively to run your application's
# test suite.  Otherwise, you never need to work with it.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Set up the master database connection for writes using masochism plugin
# NOTE: for this to work, you *must* also use config.cache_classes = true
# (default for production)
config.after_initialize do
  ActiveReload::ConnectionProxy.setup_for ActiveRecord::Base, ActiveRecord::Base
  ActiveReload::ConnectionProxy.setup_for LoggingModel, LoggingModel
end

# Most directly emulate both development and production environments:
# NOT WORKING: config.cache_store = :mem_cache_store

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Set which IP addresses generate local requests (versus public). Local requests get the default Rails error messages.
# Modify $LOCAL_REQUEST_ADDRESSES values to toggle between public and local error views when using a local IP.
$LOCAL_REQUEST_ADDRESSES = [] # ['127.0.0.1', '::1'].freeze
config.action_controller.consider_all_requests_local = false # overrides $LOCAL_REQUEST_ADDRESSES when set to true.

# Disable caching
config.action_controller.perform_caching             = false

# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test
config.cache_store = :memory_store


config.log_level = :debug # :error
# ActiveRecord::Base.logger = Logger.new(STDOUT)
# ActionController::Base.logger = Logger.new(STDOUT)
# ActiveSupport::Cache::MemCacheStore.logger = Logger.new(STDOUT)

$PARENT_CLASS_MUST_USE_MASTER = ActiveRecord::Base

$EXCEPTION_NOTIFY=false # set to false to not be notified of exceptions via email in production mode (set email addresses below)
$ENABLE_RECAPTCHA=false # set to true to enable recaptcha on registration and contact us form
$ENABLE_ANALYTICS=false
$ENABLED_SOCIAL_PLUGINS = [:facebook, :twitter] # Enable social sharing on the site e.g. Facebook Like button

$IP_ADDRESS_OF_SERVER='127.0.0.1'

$SOLR_SERVER = 'http://localhost:8983/solr/'
$SOLR_TAXON_CONCEPTS_CORE = 'taxon_concepts'
$SOLR_DATA_OBJECTS_CORE = 'data_objects'
$SOLR_SITE_SEARCH_CORE = 'site_search'
$SOLR_DIR    = Rails.root.join('solr', 'solr')
$INDEX_RECORDS_IN_SOLR_ON_SAVE = false

$SKIP_URL_VALIDATIONS = true

$HOMEPAGE_MARCH_RICHNESS_THRESHOLD = nil

config.gem 'faker'
config.gem "eol_scenarios", :lib => "eol_scenarios"
config.gem "rspec", :lib => false
config.gem "rspec-rails", :lib => false
config.gem "factory_girl", :lib => false
config.gem "capybara", :lib => false, :version => "0.3.9"
