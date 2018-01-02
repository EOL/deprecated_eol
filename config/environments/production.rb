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
  config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Disable delivery errors, bad email addresses will be ignored
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  config.action_mailer.asset_host = ENV["EOL_ASSET_HOST"]

  config.log_level = :error

  unless ENV.has_key?('LOCALE') # They already told us what to load.
    config.i18n.load_path += Dir[Rails.root.join('config', 'translations', '*.yml').to_s]
  end

  require File.expand_path('../../../lib/initializer_additions', __FILE__)

  config.before_configuration do
    config.cache_store = :dalli_store, ENV["EOL_DALLI_HOST"]
  end

  config.action_controller.asset_host = ENV["EOL_ASSET_HOST"]
  config.assets.prefix = ENV["EOL_ASSET_PREFIX"]

  config.after_initialize do

    $WEB_SERVICE_BASE_URL = ENV["EOL_WEB_SERVICE_BASE_URL"]
    $SOLR_SERVER = ENV["EOL_SOLR_SERVER"]
    $SITE_DOMAIN_OR_IP = ENV["EOL_SITE_DOMAIN_OR_IP"]

    ActionMailer::Base.delivery_method = :smtp
    # Sorry, these are no longer configurable. No one else is using them anyway.
    ActionMailer::Base.smtp_settings = {
      :address => '10.252.248.30',
      :domain => 'eol.org'
    }

    config.action_mailer.default_url_options =
      { :host => ENV["EOL_SMTP_DOMAIN"] }
    ActionMailer::Base.default_url_options[:host] = ENV["EOL_SMTP_DOMAIN"]

    $FACEBOOK_APP_ID = ENV["EOL_FACEBOOK_APP_ID"]
    $FACEBOOK_CONSUMER_KEY = ENV["EOL_FACEBOOK_CONSUMER_KEY"]
    $FACEBOOK_CONSUMER_SECRET = ENV["EOL_FACEBOOK_CONSUMER_SECRET"]
    $GOOGLE_CONSUMER_KEY = ENV["EOL_GOOGLE_CONSUMER_KEY"]
    $GOOGLE_CONSUMER_SECRET = ENV["EOL_GOOGLE_CONSUMER_SECRET"]
    $TWITTER_CONSUMER_KEY = ENV["EOL_TWITTER_CONSUMER_KEY"]
    $TWITTER_CONSUMER_SECRET = ENV["EOL_TWITTER_CONSUMER_SECRET"]
    $YAHOO_CONSUMER_KEY = ENV["EOL_YAHOO_CONSUMER_KEY"]
    $YAHOO_CONSUMER_SECRET = ENV["EOL_YAHOO_CONSUMER_SECRET"]
    $YAHOO_APP_ID = ENV["EOL_YAHOO_APP_ID"]
    $PINTEREST_VERIFICATION_CODE = ENV["EOL_PINTEREST_VERIFICATION_CODE"]
    $UNSUBSCRIBE_NOTIFICATIONS_KEY = ENV["EOL_UNSUBSCRIBE_NOTIFICATIONS_KEY"]
    $ENABLE_ANALYTICS = ENV["EOL_ENABLE_ANALYTICS"] == "true"
    $GOOGLE_ANALYTICS_ID = ENV["EOL_GOOGLE_ANALYTICS_ID"]
    $GOOGLE_UNIVERSAL_ANALYTICS_ID = ENV["EOL_GOOGLE_UNIVERSAL_ANALYTICS_ID"]
    $ENABLE_QUANTCAST = ENV["EOL_ENABLE_QUANTCAST"] == "true"
    $QUANTCAST_ID =  ENV["EOL_QUANTCAST_ID"]
    $ENABLE_WEBTRENDS = ENV["EOL_ENABLE_WEBTRENDS"] == "true"

    $VIRTUOSO_USER = ENV["EOL_VIRTUOSO_USER"]
    $VIRTUOSO_PWD = ENV["EOL_VIRTUOSO_PWD"]
    $VIRTUOSO_SPARQL_ENDPOINT_URI = ENV["EOL_VIRTUOSO_SPARQL_ENDPOINT_URI"]
    $VIRTUOSO_UPLOAD_URI = ENV["EOL_VIRTUOSO_UPLOAD_URI"]
    $VIRTUOSO_FACET_BROWSER_URI_PREFIX =
      ENV["EOL_VIRTUOSO_FACET_BROWSER_URI_PREFIX"]
    $CONTENT_PARTNER_REGISTRY_EMAIL_ADDRESS =
      ENV["EOL_CONTENT_PARTNER_REGISTRY_EMAIL_ADDRESS"]

    config.action_controller[:session] = {
      :session_key => ENV["EOL_SESSION_KEY"],
      :secret      => ENV["EOL_SESSION_SECRET"]
    }

    Resque.redis = ENV["EOL_REDIS_HOST"]

    Rails.configuration.hosted_dataset_path = ENV["EOL_HOSTED_DATASET_PATH"]
    Rails.configuration.google_site_verification_keys =
      ENV["EOL_GOOGLE_SITE_VERIFICATION_KEYS"].split

  end

end
