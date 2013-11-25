require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "active_resource/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Other Rails 1.9 libraries that needn't be gems:
require 'csv'

if defined?(Bundler)
  assets = %w(development test staging bocce_demo)
  assets << 'production' if Rails.env.production?
  Bundler.require(*Rails.groups(:assets => assets))
end

module Eol
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/extras #{config.root}/lib)
    config.autoload_paths += Dir[Rails.root.join('app', 'models', '{**}')]
    config.autoload_paths += Dir[Rails.root.join('app', 'roles')]

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Eastern Time (US & Canada)'

    # Languages that we allow through the UI (setting this early for other config files to use):
    Rails.configuration.active_languages = ['ar', 'de', 'en', 'es', 'fr', 'gl', 'ko', 'mk', 'ms', 'nl', 'nb', 'oc', 'pt-br',
      'sr', 'sr-Latn', 'sv', 'tl', 'zh-Hans', 'zh-Hant']

    # We're only loading 'en.yml' by default, here. See the other environments for how to "turn on" all the other YML files.
    # This makes startup times SO MUCH FASTER.
    if ENV.has_key?('LOCALE')
      case ENV['LOCALE']
      when 'none'
        # Do nothing. You will have no translations available. Deal with it.
      when 'active'
        config.i18n.load_path += Dir[Rails.root.join('config', 'translations',
                                                     "{#{Rails.configuration.active_languages.join(',')}}.yml").to_s]
      when 'all'
        config.i18n.load_path += Dir[Rails.root.join('config', 'translations', "*.yml").to_s]
      else
        config.i18n.load_path += Dir[Rails.root.join('config', 'translations', "#{ENV['LOCALE']}.yml").to_s]
      end
    else
      config.i18n.load_path += Dir[Rails.root.join('config', 'translations', 'en.yml').to_s]
    end
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = false

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Compile localized CSS:
    config.assets.precompile += ['*.css', '*.js']
    
    config.assets.initialize_on_precompile = false
    
    if defined?(Sass)
      config.sass.line_comments = false
      config.sass.style = :nested
    end

    # Map custom exceptions to default response codes
    config.action_dispatch.rescue_responses.update(
      'EOL::Exceptions::MustBeLoggedIn'    => :unauthorized,
      'EOL::Exceptions::Pending'           => :not_implemented,
      'EOL::Exceptions::SecurityViolation' => :forbidden,
      'OpenURI::HTTPError'                 => :bad_request
    )
    
    config.exceptions_app = ->(env) { ApplicationController.action(:rescue_from_exception).call(env) }
  end
end
