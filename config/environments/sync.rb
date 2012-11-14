#============================================================
#                     sync.rb
# Location specific settings for the sync environment
#
# Settings specified here will override those in config/environment.rb
#
# # Configuration files are loaded in the following order with the settings
# in each file overriding the settings in prior files
#
# 1) config/environment.rb
# 2) config/environments/[Rails.env].rb
# 3) config/environments/[Rails.env]_eol_org.rb
# 4) config/environment_eol_org.rb
#============================================================


# Use a different logger for distributed setups
# config.logger = SyslogLogger.new


# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.debug_rjs                         = false

# Disable delivery errors, bad email addresses will be ignored
config.action_mailer.raise_delivery_errors = false

# The sync environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# set to true to force users to use SSL for the login and signup pages 
$USE_SSL_FOR_LOGIN = false

#This part of the code should stay at the bottom to ensure that www.eol.org - related settings override everything
begin
  require File.join(File.dirname(__FILE__), 'sync_eol_org')
rescue LoadError
  puts '*************WARNING: COULD NOT LOAD SYNC_EOL_ORG FILE***********************'
end


