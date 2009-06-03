# Settings specified here will take precedence over those in config/environment.rb
# 1) config/environment.rb
# 2) config/environments/[RAILS_ENV].rb
# 3) config/environments/[RAILS_ENV]_eol_org.rb
# 4) config/environment_eol_org.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = false

# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.delivery_method = :test

config.log_level = :debug # :error

$EXCEPTION_NOTIFY=false # set to false to not be notified of exceptions via email in production mode (set email addresses below)
$ENABLE_RECAPTCHA=false # set to true to enable recaptcha on registration and contact us form
$ENABLE_ANALYTICS=false
$SHOW_SURVEYS=false

$IP_ADDRESS_OF_SERVER='127.0.0.1'
