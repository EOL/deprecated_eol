#---------------------------------------------------------------------------------
# Settings specified here will take precedence over those in config/environment.rb
# 1) config/environment.rb
# 2) config/environments/[Rails.env].rb
# 3) config/environments/[Rails.env]_eol_org.rb
# 4) config/environment_eol_org.rb
#---------------------------------------------------------------------------------
require 'ruby-debug'

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = false

# Set up the master database connection for writes using masochism plugin
# NOTE: for this to work, you *must* also use config.cache_classes = true
# (default for production)
config.after_initialize do
  ActiveReload::ConnectionProxy.setup_for ActiveRecord::Base, ActiveRecord::Base
  ActiveReload::ConnectionProxy.setup_for LoggingModel, LoggingModel
end

# Most directly emulate both development and production environments:
# NOT WORKING: config.cache_store = :dalli_store

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


  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr
  
  config.after_initialize do
    $INDEX_RECORDS_IN_SOLR_ON_SAVE = false
  end
end
