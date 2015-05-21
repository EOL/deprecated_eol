Eol::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Use content servers for thumbnails. This implies that upload_image will work (ie: you have a PHP server up and running).
  Rails.configuration.use_content_server_for_thumbnails = true

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  config.log_level = :debug

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true

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

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 1

  unless ENV.has_key?('LOCALE')
    config.i18n.load_path += Dir[Rails.root.join('config', 'translations', '*.yml').to_s]
  end

  config.action_mailer.asset_host = "http://staging.eol.org"

  require "ruby-debug"

  require File.expand_path('../../../lib/initializer_additions', __FILE__)
  InitializerAdditions.add("environments/#{Rails.env}_eol_org")

end
