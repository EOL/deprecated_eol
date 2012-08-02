# Be sure to restart your web server when you modify this file.
# This file is loaded FIRST and thus all other configuration files trump these settings.  Be careful.
# 1) config/environment.rb
# 2) config/environments/[Rails.env].rb
# 3) config/environments/[Rails.env]_eol_org.rb
# 4) config/environment_eol_org.rb

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'eol_web_service'
require 'eol'
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION
require "rubygems"
require "bundler/setup"

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :active_resource, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  config.action_controller.session = {
    :key    => '_eol_development_session',
    :secret => '9c973cddf1823632f3e42c5e25a18ecf'
  }

  # Load models in subdirectories as well.
  config.load_paths += Dir[Rails.root.join('app', 'models', '{**}']

  # require gems - all gems that don't require native compilation should be unpacked in ./vendor/gems/

  config.gem 'will_paginate'
  config.gem 'composite_primary_keys'
  config.gem 'fastercsv'
  config.gem 'haml', :version => '3.1.1'
  config.gem 'macaddr'
  config.gem 'uuid'
  config.gem 'ezcrypto'
  config.gem 'sanitize', :version => '2.0.1'
  config.gem 'escape'
  config.gem 'email_spec'
  config.gem 'invert'
  config.gem 'sass', :version => '3.1.1'

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # EOL now needs this enabled because we use table structures specific to MySQL which cannot
  # be represeted in schema.rb and we were getting test failures as a result
  config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  config.time_zone = 'UTC'

  # See Rails::Configuration for more options

  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory is automatically loaded

  config.log_level = :error

  # CONFIGURATION PARAMETERS
  # Note that some of these may be overriden in the environment specific file, check
  # in the "environments" folder for the various environments (e.g. "production.rb") to see.
  # the following only generates assests1.eol.org or assets2.eol.org on up to any number specified below
  #config.action_controller.asset_host = "http://content0.eol.org"

  # As of this writing, this is used for two things:
  #   1) Avoid harmful migrations in production using #raise_error_if_in_production, and
  #   2) Log errors to NewRelic if we're in production (or on staging).
  $PRODUCTION_MODE = Rails.env.production? || Rails.env.staging? || Rails.env.sync?

  # How many images we want to show, at maximum, for a given page.  This number should be lower than the maximum
  # number of images created in the cached_images tables.  (EOL presently sets cached_image limits at 500.)
  $IMAGE_LIMIT = 200

  # THIS IS WHERE ALL THE IMAGES/VIDEOS LIVE:
  $CONTENT_SERVERS = ['http://localhost/']
  $CONTENT_SERVER_CONTENT_PATH = "content" # if you put leading and trailing slashes here you get double slashes in the URLs, which work fine but aren't right
  $CONTENT_SERVER_RESOURCES_PATH = "/resources/"
  $CONTENT_SERVER_AGENT_LOGOS_PATH = "/content_partners/"
  $SINGLE_DOMAIN_CONTENT_SERVER = 'http://localhost/'
  $SPECIES_IMAGE_FORMAT = "jpg" # the extension of all species images on the content server

  # MEDIA CENTER CONFIGURATION
  $MAX_IMAGES_PER_PAGE = 40 # number of thumbnail images to show per page
  $PREFER_REMOTE_IMAGES = false # if set to true, then remote image URLs are used to show images when possible (helpful to preserve EOL bandwidth if needed)

  $SHOW_DATA_QUALITY = false # if set to true, we will show data quality next to text content blocks

  # Note that you can override this in the environment-specific file, too, if you want to.
  $DEFAULT_HIERARCHY_NAME = "Species 2000 & ITIS Catalogue of Life: May 2012"

  # TODO - Remove all references to "content levels" here and in the code --- this is all not required anymore
  ################
  $DEFAULT_CONTENT_LEVEL = "1" # default content level for types of pages shown to user (1..4)
           # 1 == all names
           # 2 == any page which has content, including aggregated from children
           # 3 == only pages that have at least once piece of content tied directly to them
           # 4 == only pages that have a picture and a piece of text tied directly to them
  $VALID_CONTENT_LEVEL = 1 # level that pages must be greater than or equal to for links to be created in the flash classification browser
  $ALLOW_USER_TO_CHANGE_CONTENT_LEVEL = false # if set to true, user can change their content level
  $ALLOW_SECOND_HIERARCHY = false # if true, the user can pick a second filter hierarchy (confusing but powerful)
  #################

  $ALLOW_USER_LOGINS = true # if set to false, user login and registration area is not linked or shown on page
  $ENABLE_RECAPTCHA = true # set to true to enable recaptcha on registration and contact us form
  $MAX_SEARCH_RESULTS = 200 # the maximum possible number of search results that can be returned
  $USE_EXTERNAL_LINK_POPUPS = false # if set to true, then attribution and other links will create a pop-up javascript when linking to external sites
  $ALLOW_CURATOR_SELF_REG = true # set to allow curators to self-register
  $USE_SSL_FOR_LOGIN = false # set to true to force users to use SSL for the login and signup pages
  $ENABLED_SOCIAL_PLUGINS = [:facebook, :google, :twitter, :yahoo] # Enable open authentication and social sharing on the site e.g. Facebook Like button

  # DATA LOGGING CONFIGURATION
  $ENABLE_DATA_LOGGING = true # set to true to enable data usage and search term logging in logging database

  # ERROR HANDLING CONFIGURATION
  $EXCEPTION_NOTIFY = false # set to false to not be notified of exceptions via email in production mode (set email addresses below)
  $ERROR_LOGGING = true # set to true to record uncaught application errors in sql database file
  $EXCEPTION_EMAIL_ADDRESS = %("EOL Application Error" <no-reply@example.comma>)
  $IGNORED_EXCEPTIONS = ["CGI::Session::CookieStore::TamperedWithCookie","taxa id not supplied"] # array of exceptions to ignore when logging or notifying

  # EMAIL NOTIFIER CONFIGURATION
  $SPECIES_PAGES_GROUP_EMAIL_ADDRESS = "from@example.com"
  $SUPPORT_EMAIL_ADDRESS = "from@example.com"
  $ERROR_EMAIL_ADDRESS = "from@example.com"
  $STATISTICS_EMAIL_FROM_ADDRESS = "from@example.com"
  $EDUCATION_EMAIL = 'from@example.com'
  $MEDIA_INQUIRY_CONTACT_SUBJECT_ID = 1 # this should match the ContactSubject table with the ID of the media inquiry row (used on the special Media Contact page)
  $CONTRIBUTE_INQUIRY_CONTACT_SUBJECT_IDS = "13,14" # this should match the ContactSubject table with the IDs of the request to curate or contribute rows as a string in comma delimuted format  (used on the Contact us page to show an extra field)

  # CACHE CONFIGURATION
  $CACHE_CLEARED_LAST = Time.now()  # This variable will record the last time the home page cache was cleared
  $CACHE_CLEAR_IN_HOURS = 1 # automatically expire home page cached fragment at this time interval
  $CACHE_STATS_COUNT_IN_MINUTES = 24 * 60 # refresh total counts of all data at this time interval

  # CONTENT PARTNER REGISTRY CONFIGURATION
  $LOGO_UPLOAD_PATH = "/uploads/images/collection_icons/"  # directory to place uploaded content partner logos from CP registry, content server needs SFTP access to this folder (logos are not served out of this area)
  $LOGO_UPLOAD_DIRECTORY = "#{Rails.root.join(Rails.public_path, 'uploads', 'images', 'collection_icons')}/:class_:id.:extension"  # directory to place uploaded content partner logos from CP registry, content server needs SFTP access to this folder (logos are not server out of this area)
  $LOGO_UPLOAD_MAX_SIZE = 5242880 # 5 megabytes
  $DATASET_UPLOAD_PATH = "/uploads/datasets/"  # directory to place uploaded content partner datasets, content server needs SFTP access to this folder
  $DATASET_UPLOAD_DIRECTORY = "#{Rails.root.join(Rails.public_path, 'uploads', 'datasets')}/:id.:extension" # directory to place uploaded content partner datasets, content server needs SFTP access to this folder

  $CONTENT_UPLOAD_PATH = "/uploads/"  # directory to place uploaded content files, content server needs SFTP access to this folder
  $CONTENT_UPLOAD_DIRECTORY = "#{Rails.root.join(Rails.public_path, 'uploads')}/:id.:extension"  # directory to place uploaded content

  # NEWS ITEMS ON HOME PAGE CONFIGURATION
  $NEWS_ITEMS_HOMEPAGE_MAX_DISPLAY = 5 # the maximum number of news items to show on the home page at any time
  $NEWS_ITEMS_TIMEOUT_HOMEPAGE_WEEKS = 8 # the number of weeks before a news item automatically disappears from the home page (determined by the "display date")

  # WEBSERVICE CONFIGURATION
  $WEB_SERVICE_TIMEOUT_SECONDS = 60 # how many seconds to wait when calling a webservice before timing out and returning nil
  $LOG_WEB_SERVICE_EXECUTION_TIME = false # if set to false, then execution times for web service calls will not be recorded
  $WEB_SERVICE_BASE_URL = '' # web service is used for importing content partners' data

  $SOLR_SERVER = 'http://localhost:8983/solr/'
  $SOLR_TAXON_CONCEPTS_CORE = 'taxon_concepts'
  $SOLR_DATA_OBJECTS_CORE = 'data_objects'
  $SOLR_SITE_SEARCH_CORE = 'site_search'
  $SOLR_COLLECTION_ITEMS_CORE = 'collection_items'
  $SOLR_ACTIVITY_LOGS_CORE = 'activity_logs'
  $SOLR_BHL_CORE = 'bhl'
  $SOLR_DIR    = Rails.root.join('solr', 'solr')
  $INDEX_RECORDS_IN_SOLR_ON_SAVE = true

  ### These next few values are declared in the eol:site_configurations table. They are also declared here
  ### beacuse when we switch to SI we will not be able to edit the database and need to be able to tweak the
  ### environment file to possibly override the values in the DB
  # $REFERENCE_PARSING_ENABLED = false
  # $REFERENCE_PARSER_ENDPOINT = **the URL of the reference parsing script**
  # $REFERENCE_PARSER_PID = **the email address of the crossref user account**

  #Server's IP address
  $IP_ADDRESS_OF_SERVER = EOLWebService.local_ip
  $SITE_DOMAIN_OR_IP = $IP_ADDRESS_OF_SERVER #domain name for url links communicated outside, for example for emails

  # Default values for some language-dependent strings used by models:
  $CURATOR_ROLE_NAME   = 'Curator'
  $ADMIN_ROLE_NAME     = 'Administrator'
  $ASSOCIATE_ROLE_NAME = 'Associate'

  # Default Values for some language-dependent titles:
  $ADMIN_CONSOLE_TITLE = 'EOL Administration Console'
  $CURATOR_CENTRAL_TITLE = 'Curator Central'

  $MYSQLDUMP_COMPLETE_PATH = 'mysqldump'

  $AGENT_ID_OF_DEFAULT_COMMON_NAME_SOURCE = 9448

  $MAX_TAXA_TO_EXPIRE_BEFORE_EXPIRING_ALL = 1024

  $MAX_COLLECTION_ITEMS_TO_MANIPULATE = 1000

  $BACKGROUND_TASK_USER_ID = 1 # The user ID which will be used for comments left by background jobs.
  $SPECIAL_COMMUNITY_NAME = 'EOL Curators and Admins'
  $RICH_PAGES_COLLECTION_ID = 34 # Please keep this variable around as a "reasonable default" for when lang keys are missing... though you should update the value as needed (probably with the value of :en in RICH_LANG_PAGES_COLLECTION_IDS)
  $RICH_LANG_PAGES_COLLECTION_IDS = {:en => 34, :es => 6496, :ar => 7745}

  $ACTIVITIES_ON_HOME_PAGE = 6
  $HOMEPAGE_ACTIVITY_LOG_CACHE_TIME = 10  # minutes
  $HOMEPAGE_MARCH_RICHNESS_THRESHOLD = 0.5

  APPLICATION_DEFAULT_LANGUAGE_ISO = 'en'
  APPROVED_LANGUAGES = ['en', 'es', 'ar', 'fr', 'gl', 'sr', 'sr-Latn', 'de', 'mk', 'zh-Hans']

  # for those class that are using CACHE_ALL_ROWS, when the row is looked up in memcached, retain that value
  # in an array in a class variable. That way future lookups will read from local memory and will not require
  # back and forth from Memcached
  $USE_LOCAL_CACHE_CLASSES = true

  $ENABLE_TRANSLATION_LOGS = false # This is expensive; DON'T do it by default!

  # If this is false, mail errors are silently ignored.  That doesn't make us happy:
  config.action_mailer.raise_delivery_errors = true
  # URLs are not handled correctly in email (IMO), but this fixes it:
  config.action_mailer.default_url_options = { :host => "eol.org" }

  # Default values for some footer elements:
  $EOL_TWITTER_ACCOUNT  = "http://twitter.com/#!/EOL"
  $EOL_FACEBOOK_ACCOUNT = "http://www.facebook.com/encyclopediaoflife"
  $EOL_TUMBLR_ACCOUNT   = "http://blog.eol.org"
  $EOL_FLICKR_ACCOUNT   = "http://www.flickr.com/groups/encyclopedia_of_life/"
  $EOL_YOUTUBE_ACCOUNT  = "http://www.youtube.com/user/EncyclopediaOfLife/"

  $CURATOR_COMMUNITY_NAME = 'EOL Curators'
  $CURATOR_COMMUNITY_DESC = 'This is a special community intended for EOL curators to discuss matters related to curation on the Encylopedia of Life.'


  begin
    require 'config/environments/local.rb'
  rescue LoadError
    #puts 'Could not load environments local.rb file'
  end

  identity_yml_path = File.join(File.dirname(__FILE__), 'identity.yml')
  if FileTest.exist? identity_yml_path

    source = YAML::load(File.open(identity_yml_path))
    $IP_ADDRESS_OF_SERVER = source['ip_address']
  end

end

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
  :long => "%A, %B %d, %Y - %I:%M %p %Z",
  :short_no_time => "%m/%d/%Y",
  :short_no_tz => "%m/%d/%Y - %I:%M %p"
)

# Windows users are colorblind:
ActiveRecord::Base.colorize_logging = false if PLATFORM =~ /win32/

# Recaptcha Keys
ENV['RECAPTCHA_PUBLIC_KEY'] = ''
ENV['RECAPTCHA_PRIVATE_KEY'] = ''

# Assign it during deployment with capistrano
ENV['APP_VERSION'] = ''

WillPaginate::ViewHelpers.pagination_options[:previous_label] = I18n.t(:search_previous_label)
WillPaginate::ViewHelpers.pagination_options[:next_label] = I18n.t(:search_next_label)

# Required by the User model and the Account Controller, at least:
require 'uri'
require 'ezcrypto'
require 'cgi'
require 'base64'

# Add some stuff to Core/Rails base classes:
require 'core_extensions'
require 'select_with_preload_include'
require 'open-uri'

#This part of the code should stay at the bottom to ensure that www.eol.org - related settings override everything
begin
  require 'config/environment_eol_org'
rescue LoadError
end

$CACHE = Rails.cache

# Taken right from http://tinyurl.com/3xzen6z
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked # We're in smart spawning mode.
      $CACHE = Rails.cache.clone
      # see http://tinyurl.com/4dz7awo for the fix for those using the built-in Rails.cache
      $CACHE.instance_variable_get(:@data).reset if $CACHE.class == ActiveSupport::Cache::MemCacheStore
    else
      # We're in conservative spawning mode. We don't need to do anything.
    end
  end
end

# load the system configuration
require File.dirname(__FILE__) + '/system' if File.file?(File.dirname(__FILE__) + '/system.rb')
NewRelic::Agent.after_fork(:force_reconnect => true)
