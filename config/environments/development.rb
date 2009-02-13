# Settings specified here will take precedence over those in config/environment.rb

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.cache_classes                                 = false
config.action_view.debug_rjs                         = false

#config.cache_store = :mem_cache_store, '127.0.0.1:11211'
config.cache_store = :file_store, "/data/cache"
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

#set up the master database connection for writes using masochism plugin
#NOTE: for this to work, you *must* also use config.cache_classes = true (default for production)
# config.after_initialize do 
#   ActiveReload::ConnectionProxy.setup_for ActiveReload::MasterDatabase, ActiveRecord::Base
#   ActiveReload::ConnectionProxy.setup_for SpeciesSchemaWriter, SpeciesSchemaModel          
# end

# uncomment the line below if you want to use the minified/combined JS files from the asset packager for testing purposes
# note that to create new combined asset files, use this rake task first: rake asset:packager:build_all
#Synthesis::AssetPackage.merge_environments = ["development", "production"] 
