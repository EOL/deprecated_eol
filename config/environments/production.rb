Eol::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Use content servers for thumbnails. This implies that upload_image will work (ie: you have a PHP server up and running).
  Rails.configuration.use_content_server_for_thumbnails = true

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Allow removal of expired assets:
  config.assets.handle_expiration = true
  config.assets.expire_after 2.months

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  $VIRTUOSO_USER = 'dba'
  $VIRTUOSO_PW = 'dba'
  $VIRTUOSO_SPARQL_ENDPOINT_URI = 'http://localhost:8890/sparql'
  $VIRTUOSO_UPLOAD_URI = 'http://localhost:8890/DAV/home/dba/upload'
  $VIRTUOSO_FACET_BROWSER_URI_PREFIX = 'http://localhost:8890/describe/?url='
  $VIRTUOSO_CACHING_PERIOD = 12 # HOURS

  # Generate digests for assets URLs
  config.assets.digest = true

  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  config.action_mailer.asset_host = "http://eol.org"

  config.log_level = :error

  unless ENV.has_key?('LOCALE') # They already told us what to load.
    config.i18n.load_path += Dir[Rails.root.join('config', 'translations', '*.yml').to_s]
  end

  # # Send deprecation notices to registered listeners
  # config.active_support.deprecation = :notify

  require File.expand_path('../../../lib/initializer_additions', __FILE__)
  InitializerAdditions.add("environments/#{Rails.env}_eol_org")

end
