# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.debug_rjs                         = false

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
config.action_mailer.raise_delivery_errors = false

# ENVIRONMENT SPECIFIC CONFIGURATION

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
:address => "rubus.eol.org",
:port => 25,
:domain => "eol.org",
} 

$ENABLE_ANALYTICS=false
$SHOW_SURVEYS=false

$EXCEPTION_NOTIFY=false # set to false to not be notified of exceptions via email in production mode (set email addresses below)
$ERROR_LOGGING=false # set to true to record uncaught application errors in sql database file 

