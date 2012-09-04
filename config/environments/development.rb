# Settings specified here will take precedence over those in config/environment.rb
# 1) config/environment.rb
# 2) config/environments/[Rails.env].rb
# 3) config/environments/[Rails.env]_eol_org.rb
# 4) config/environment_eol_org.rb

# Allow breakpoints in mongrel:
require "ruby-debug"

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Set which IP addresses generate local requests (versus public). Local requests get the default Rails error messages.
# Modify $LOCAL_REQUEST_ADDRESSES values to toggle between public and local error views when using a local IP.
$LOCAL_REQUEST_ADDRESSES = [] # ['127.0.0.1', '::1'].freeze
config.action_controller.consider_all_requests_local = false # overrides $LOCAL_REQUEST_ADDRESSES when set to true.

# Disable caching
config.cache_classes                                 = false
config.action_view.debug_rjs                         = false

# We have code that RELIES on memcached running, so you MUST use this (or find a brilliant way to fix the code):
config.cache_store = :dalli_store
#config.cache_store = :memory_store
#(you might be able to use memory_store if you don't have memcached installed when in development, but it might behave funny)

### TO ENABLE CACHING ... ( make sure the config.cache_store is setup and it exists!  note: file_store uses an absolute path )
config.action_controller.perform_caching             = false # Of course, you want to make this true if you're testing it.
### ^ to enable fragment caching for testing set to true...

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 1

$PARENT_CLASS_MUST_USE_MASTER = ActiveRecord::Base

  # Expands the lines which load the assets
  config.assets.debug = true
  
  # ActiveRecord::Base.logger = Logger.new(STDOUT)
  # ActionController::Base.logger = Logger.new(STDOUT)
  # Dalli.logger = Logger.new(STDOUT)
  
end
