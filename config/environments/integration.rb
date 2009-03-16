# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = false

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = false
config.action_view.debug_rjs                         = false

#config.cache_store = :mem_cache_store, '127.0.0.1:11211'
config.cache_store = :file_store, "/data/cache"

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false
config.log_level = :debug

# OVERRIDEN BASE CONFIGURATION
$EXCEPTION_NOTIFY=false # set to false to not be notified of exceptions via email in production mode (set email addresses below)
$ERROR_LOGGING=true # set to true to record uncaught application errors in sql database file 
$ENABLE_RECAPTCHA=false # set to true to enable recaptcha on registration and contact us form

$ENABLE_ANALYTICS=false
$SHOW_SURVEYS=false  
