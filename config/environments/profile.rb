# Settings specified here will take precedence over those in config/environment.rb

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.debug_rjs                         = false

# Enable serving of images, stylesheets, and javascripts from an asset server (the %d assumes we will have assets0.eol.org to assets3.eol.org)
# config.action_controller.asset_host                  = "http://assets%d.eol.org"

# the following only generates assests1.eol.org or assets2.eol.org
# config.action_controller.asset_host = Proc.new { |source| "http://assets#{rand(2) + 1}.eol.org" }

# the following only generates assests.eol.org 
# config.action_controller.asset_host                  = "http://assets.eol.org"

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
