# Settings specified here will take precedence over those in config/environment.rb
# 1) config/environment.rb
# 2) config/environments/[RAILS_ENV].rb
# 3) config/environments/[RAILS_ENV]_eol_org.rb
# 4) config/environment_eol_org.rb

# Allow breakpoints in mongrel:
require "ruby-debug"

config.whiny_nils = true
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching = true
config.action_view.debug_rjs = false
config.cache_classes = true
config.action_mailer.raise_delivery_errors = false

config.log_level = :error

$PARENT_CLASS_MUST_USE_MASTER = ActiveRecord::Base
$LOG_USER_ACTIVITY = true
$EXCEPTION_NOTIFY = true
$ERROR_LOGGING = true
$ENABLE_ANALYTICS = false
$ENABLE_RECAPTCHA = false
$LOG_WEB_SERVICE_EXECUTION_TIME = true
$USE_SSL_FOR_LOGIN = false



#This part of the code should stay at the bottom to ensure that www.eol.org - related settings override everything
begin
  require File.join(File.dirname(__FILE__), 'sync_eol_org')
rescue LoadError
  puts '*************WARNING: COULD NOT LOAD SYNC_EOL_ORG FILE***********************'
end

