# Settings specified here will take precedence over those in config/environment.rb
# 1) config/environment.rb
# 2) config/environments/[RAILS_ENV].rb
# 3) config/environments/[RAILS_ENV]_eol_org.rb
# 4) config/environment_eol_org.rb

# Allow breakpoints in mongrel:
require "ruby-debug"

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
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

$EXCEPTION_NOTIFY=true # set to false to not be notified of exceptions via email
$ERROR_LOGGING=true # set to true to record uncaught application errors in sql database file 

$SHOW_SURVEYS=false # set to true to show surveys; logic on when to show surveys is set in the "show_survey?" method in the application controller
$ENABLE_ANALYTICS=false 
$ENABLE_RECAPTCHA=false # set to true to enable recaptcha on registration and contact us form

#$WEB_SERVICE_TIMEOUT_SECONDS=20 # how many seconds to wait when calling a webservice before timing out and returning nil
$LOG_WEB_SERVICE_EXECUTION_TIME=true # if set to false, then execution times for web service calls will not be recorded
$USE_SSL_FOR_LOGIN=false

# THIS IS WHERE ALL THE IMAGES/VIDEOS LIVE:
$CONTENT_SERVERS = ['http://content.eol.org/'] if !$CONTENT_SERVERS

#set up the master database connection for writes using masochism plugin
#NOTE: for this to work, you *must* also use config.cache_classes = true (default for production)
# config.after_initialize do 
#   ActiveReload::ConnectionProxy.setup_for ActiveReload::MasterDatabase, ActiveRecord::Base
#   ActiveReload::ConnectionProxy.setup_for SpeciesSchemaWriter, SpeciesSchemaModel          
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
