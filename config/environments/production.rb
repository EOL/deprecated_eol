# Settings specified here will take precedence over those in config/environment.rb

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.debug_rjs                         = false

# Disable delivery errors, bad email addresses will be ignored
config.action_mailer.raise_delivery_errors = false

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

#set up the master database connection for writes using masochism plugin
# NOTE: for this to work, you *must* also use config.cache_classes = true (default for production)
config.after_initialize do 
  ActiveReload::ConnectionProxy.setup_for ActiveReload::MasterDatabase, ActiveRecord::Base
  ActiveReload::ConnectionProxy.setup_for SpeciesSchemaWriter, SpeciesSchemaModel
  ActiveReload::ConnectionProxy.setup_for LoggingWriter, LoggingModel
end

#This part of the code should stay at the bottom to ensure that www.eol.org - related settings override everything
begin
  require File.join(File.dirname(__FILE__), 'production_eol_org')
rescue LoadError
  puts '*************WARNING: COULD NOT LOAD PRODUCTION_EOL_ORG FILE***********************'
end

$USE_SSL_FOR_LOGIN = true # set to true to force users to use SSL for the login and signup pages 
