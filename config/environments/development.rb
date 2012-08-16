# Settings specified here will take precedence over those in config/environment.rb
# 1) config/environment.rb
# 2) config/environments/[RAILS_ENV].rb
# 3) config/environments/[RAILS_ENV]_eol_org.rb
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

# We have code that RELIES on mem_cache running, so you MUST use this (or find a brilliant way to fix the code):
config.cache_store = :mem_cache_store
#config.cache_store = :memory_store
#(you might be able to use memory_store if you don't have memcached installed when in development, but it might behave funny)

### TO ENABLE CACHING ... ( make sure the config.cache_store is setup and it exists!  note: file_store uses an absolute path )
config.action_controller.perform_caching             = false # Of course, you want to make this true if you're testing it.
### ^ to enable fragment caching for testing set to true...

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

config.log_level = :debug # :error
if ENV['RAILS_ENV'] == 'development'
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActionController::Base.logger = Logger.new(STDOUT)
  ActiveSupport::Cache::MemCacheStore.logger = Logger.new(STDOUT)
end

$PARENT_CLASS_MUST_USE_MASTER = ActiveRecord::Base

$LOG_USER_ACTIVITY = true

$EXCEPTION_NOTIFY = false # set to false to not be notified of exceptions via email
$ERROR_LOGGING = false # set to true to record uncaught application errors in sql database file

$ENABLE_ANALYTICS=false
$ENABLE_RECAPTCHA=false # set to true to enable recaptcha on registration and contact us form
#$WEB_SERVICE_TIMEOUT_SECONDS=20 # how many seconds to wait when calling a webservice before timing out and returning nil
$LOG_WEB_SERVICE_EXECUTION_TIME=true # if set to false, then execution times for web service calls will not be recorded
$USE_SSL_FOR_LOGIN=false

# THIS IS WHERE ALL THE IMAGES/VIDEOS LIVE:
$CONTENT_SERVERS = ['http://content.eol.org/'] if !$CONTENT_SERVERS

$AGENT_ID_OF_DEFAULT_COMMON_NAME_SOURCE = Agent.first.id rescue nil # Because it doesn't much matter, here in development.

$SKIP_URL_VALIDATIONS = true

$IP_ADDRESS_OF_SERVER = '0.0.0.0:3000'

$UNSUBSCRIBE_NOTIFICATIONS_KEY = 'f0de2a0651aa88a090e5679e5e3a7d28'

$HOMEPAGE_MARCH_RICHNESS_THRESHOLD = nil

# # If you decide you want to view the site using the V1 layout then comment out the next line
# $USE_OLD_MAIN_LAYOUT = true

#set up the master database connection for writes using masochism plugin
#NOTE: for this to work, you *must* also use config.cache_classes = true (default for production)
# config.after_initialize do
#   ActiveReload::ConnectionProxy.setup_for ActiveReload::MasterDatabase, ActiveRecord::Base
# end

# uncomment the line below if you want to use the minified/combined JS files from the asset packager for testing purposes
# note that to create new combined asset files, use this rake task first: rake asset:packager:build_all
#Synthesis::AssetPackage.merge_environments = ["development", "production"]

#This part of the code should stay at the bottom to ensure that www.eol.org - related settings override everything
begin
  require File.join(File.dirname(__FILE__), 'development_eol_org')
rescue LoadError
  puts '*************WARNING: COULD NOT LOAD development_eol_org FILE***********************'
end
