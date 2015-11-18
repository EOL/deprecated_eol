# Settings specified here will take precedence over those in config/environment.rb

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.debug_rjs                         = false

# Disable delivery errors, bad email addresses will be ignored
config.action_mailer.raise_delivery_errors = false

# ENVIRONMENT SPECIFIC CONFIGURATION
$ENABLE_ANALYTICS=true # set to true to enable google analytics

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
:address => "rubus.eol.org",
:port => 25,
:domain => "eol.org",
} 

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true
