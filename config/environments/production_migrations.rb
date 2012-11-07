EolUpgrade::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Set up the master database connection for writes using masochism plugin
  # NOTE: for this to work, you *must* also use config.cache_classes = true (default for production)
  config.after_initialize do
    ActiveReload::ConnectionProxy.setup_for ActiveReload::MasterDatabase, ActiveRecord::Base
    ActiveReload::ConnectionProxy.setup_for LoggingWriter, LoggingModel
    $PARENT_CLASS_MUST_USE_MASTER = ActiveReload::MasterDatabase
  end
  $LOGGING_READ_FROM_MASTER = true

  # # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # # the I18n.default_locale when a translation can not be found)
  # config.i18n.fallbacks = true

  # # Send deprecation notices to registered listeners
  # config.active_support.deprecation = :notify
end
