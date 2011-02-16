# Be sure to restart your web server when you modify this file.
# This file is loaded FIRST and thus all other configuration files trump these settings.  Be careful.
# 1) config/environment.rb
# 2) config/environments/[RAILS_ENV].rb
# 3) config/environments/[RAILS_ENV]_eol_org.rb
# 4) config/environment_eol_org.rb

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'eol_web_service'
require 'eol'
RAILS_GEM_VERSION = '2.3.8' unless defined? RAILS_GEM_VERSION

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :active_resource, :action_mailer ]
 
  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  config.action_controller.session = {
    :key    => '_eol_development_session',
    :secret => '9c973cddf1823632f3e42c5e25a18ecf'
  }

  # #Load vendor'ed gems
  # config.load_paths += Dir["#{RAILS_ROOT}/vendor/gems/**"].map do |dir| 
  #   File.directory?(lib = "#{dir}/lib") ? lib : dir
  # end
  
  # Load models in subdirectories as well.
  config.load_paths += Dir["#{RAILS_ROOT}/app/models/**"].map { |dir| dir }

  # require gems - all gems that don't require native compilation should be unpacked in ./vendor/gems/
  config.gem 'will_paginate'
  config.gem 'composite_primary_keys'
  config.gem 'fastercsv'
  config.gem 'haml'
  config.gem 'macaddr'
  config.gem 'uuid'
  config.gem 'ezcrypto'
  config.gem 'sanitize'
  config.gem 'escape'
  config.gem 'email_spec'
  config.gem 'jrails'

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

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

  # We have a lot of production-like environments.  To quickly test if we're in one, rather than parsing the ENV,
  # you may check $PRODUCTION_MODE.
  $PRODUCTION_MODE = true if ENV['RAILS_ENV'] and
    ['production', 'staging', 'siproduction', 'failover', 'preview'].include?(ENV['RAILS_ENV'].downcase)
    
  # How many images we want to show, at maximum, for a given page.  This number should be lower than the maximum number of
  # images created in the cached_images tables.  (EOL presently sets cached_image limits at 500.)
  $IMAGE_LIMIT = 200

  # THIS IS WHERE ALL THE IMAGES/VIDEOS LIVE:
  $CONTENT_SERVERS = ['http://content1.eol.org/', 'http://content2.eol.org/', 'http://content3.eol.org/', 'http://content4.eol.org/', 'http://content5.eol.org/', 
                      'http://content6.eol.org/', 'http://content7.eol.org/', 'http://content8.eol.org/', 'http://content9.eol.org/', 'http://content10.eol.org/']
  
  $CONTENT_SERVER_CONTENT_PATH = "content" # if you put leading and trailing slashes here you get double slashes in the URLs, which work fine but aren't right
  $CONTENT_SERVER_RESOURCES_PATH = "/resources/"
  $CONTENT_SERVER_AGENT_LOGOS_PATH = "/content_partners/"
  $SPECIES_IMAGE_FORMAT = "jpg" # the extension of all species images on the content server
  
  # MEDIA CENTER CONFIGURATION
  $MAX_IMAGES_PER_PAGE = 9 # number of thumbnail images to show per page
  $PREFER_REMOTE_IMAGES = false # if set to true, then remote image URLs are used to show images when possible (helpful to preserve EOL bandwidth if needed)
  
  $SHOW_DATA_QUALITY = false # if set to true, we will show data quality next to text content blocks
  
  # TAXONOMIC BROWSER CONFIGURATION
  $MAX_TREE_LEVELS = 12 # maximum number of tree levels to show in text-based taxonomic browser
  $DEFAULT_TAXONOMIC_BROWSER = "text" # can be either text or flash

  # Note that you can override this in the environment-specific file, too, if you want to.
  $DEFAULT_HIERARCHY_NAME = "Species 2000 & ITIS Catalogue of Life: Annual Checklist 2010"
  
  # SITE CONTENT CONFIGURATION
  $DEFAULT_VETTED = false # default to showing all content (changed October 6, 2009 by Peter Mangiafico at request of Gary Borisy)
  $DEFAULT_EXPERTISE = :expert # default expertise level (options are :middle, :novice, :expert)
  $DEFAULT_TITLE_EXPERTISE = :italicized_canonical
  $DEFAULT_SUBTITLE_EXPERTISE = :middle

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
  
  # DATA LOGGING CONFIGURATION
  $ENABLE_DATA_LOGGING = true # set to true to enable data usage and search term logging in logging database
  
  # ERROR HANDLING CONFIGURATION
  $EXCEPTION_NOTIFY = false # set to false to not be notified of exceptions via email in production mode (set email addresses below)
  $ERROR_LOGGING = true # set to true to record uncaught application errors in sql database file 
  $EXCEPTION_EMAIL_ADDRESS = %("EOL Application Error" <no-reply@example.comma>) 
  $IGNORED_EXCEPTIONS = ["CGI::Session::CookieStore::TamperedWithCookie","taxa id not supplied","static page without id"] # array of exceptions to ignore when logging or notifying
  
  # EMAIL NOTIFIER CONFIGURATION
  $WEBSITE_EMAIL_FROM_ADDRESS = "from@example.com"
  $STATISTICS_EMAIL_FROM_ADDRESS = "from@example.com"
  $MEDIA_INQUIRY_CONTACT_SUBJECT_ID = 1 # this should match the ContactSubject table with the ID of the media inquiry row (used on the special Media Contact page)
  $CONTRIBUTE_INQUIRY_CONTACT_SUBJECT_IDS = "13,14" # this should match the ContactSubject table with the IDs of the request to curate or contribute rows as a string in comma delimuted format  (used on the Contact us page to show an extra field)
  $CONTENT_PARTNER_REGISTRY_EMAIL_ADDRESS = "content@example.com" # the contact us form on the data partner registry goes into this address
 
  # SESSION MANAGEMENT
  $SESSION_EXPIRY_IN_SECONDS = (60*60) # the number of seconds of non-use before sessions are automatically expired in SQL
  $USE_SQL_SESSION_MANAGEMENT = false   # set to true to use Rails built-in SQL session storage management
   # (create the session table with 'rake db:sessions:create')

   # CACHE CONFIGURATION
   $CACHE_CLEARED_LAST = Time.now()  # This variable will record the last time the home page cache was cleared
   $CACHE_CLEAR_IN_HOURS = 1 # automatically expire home page cached fragment at this time interval (in hours)
 
  # CONTENT PARTNER REGISTRY CONFIGURATION
  $LOGO_UPLOAD_PATH = "/uploads/images/collection_icons/"  # directory to place uploaded content partner logos from CP registry, content server needs SFTP access to this folder (logos are not served out of this area)
  $LOGO_UPLOAD_DIRECTORY = "#{RAILS_ROOT}/public/uploads/images/collection_icons/:id.:extension"  # directory to place uploaded content partner logos from CP registry, content server needs SFTP access to this folder (logos are not server out of this area)
  $DATASET_UPLOAD_PATH = "/uploads/datasets/"  # directory to place uploaded content partner datasets, content server needs SFTP access to this folder 
  $DATASET_UPLOAD_DIRECTORY = "#{RAILS_ROOT}/public/uploads/datasets/:id.:extension"  # directory to place uploaded content partner datasets, content server needs SFTP access to this folder 

  $CONTENT_UPLOAD_PATH = "/uploads/"  # directory to place uploaded content files, content server needs SFTP access to this folder 
  $CONTENT_UPLOAD_DIRECTORY = "#{RAILS_ROOT}/public/uploads/:id.:extension"  # directory to place uploaded content
    
  # NEWS ITEMS ON HOME PAGE CONFIGURATION
  $NEWS_ITEMS_HOMEPAGE_MAX_DISPLAY = 5 # the maximum number of news items to show on the home page at any time
  $NEWS_ITEMS_TIMEOUT_HOMEPAGE_WEEKS = 8 # the number of weeks before a news item automatically disappears from the home page (determined by the "display date")
  
  # WEBSERVICE CONFIGURATION
  $WEB_SERVICE_TIMEOUT_SECONDS = 60 # how many seconds to wait when calling a webservice before timing out and returning nil
  $LOG_WEB_SERVICE_EXECUTION_TIME = false # if set to false, then execution times for web service calls will not be recorded
  $WEB_SERVICE_BASE_URL = '' # web service is used for importing content partners' data


  $SOLR_SERVER = 'http://localhost:8983/solr/taxon_concepts'
  $SOLR_SERVER_DATA_OBJECTS = 'http://localhost:8983/solr/data_objects'
  $SOLR_DIR    = File.join(RAILS_ROOT, 'solr', 'solr')
  
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

  $SPECIAL_COMMUNITY_NAME = 'EOL Curators and Admins'

  if $USE_SQL_SESSION_MANAGEMENT
    config.action_controller.session_store = :active_record_store
  end
  
  begin
    require 'config/environments/local.rb'
  rescue LoadError
    #puts 'Could not load environments local.rb file'
  end

end

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
  :long => "%A, %B %d, %Y - %I:%M %p %Z",
  :short_no_time => "%m/%d/%Y",
  :short_no_tz => "%m/%d/%Y - %I:%M %p"
)

if $USE_SQL_SESSION_MANAGEMENT
  CGI::Session::ActiveRecordStore::Session.connection = ActiveRecord::Base.establish_connection("master_database")
end

# Windows users are colorblind:
ActiveRecord::Base.colorize_logging = false if PLATFORM =~ /win32/

# Recaptcha Keys
ENV['RECAPTCHA_PUBLIC_KEY'] = ''
ENV['RECAPTCHA_PRIVATE_KEY'] = ''

# Assign it during deployment with capistrano 
ENV['APP_VERSION'] = ''

# if exception_notify is true, configure below
ExceptionNotifier.exception_recipients = [] # email addresses of people to get exception notifications, separated by spaces, blank array if nobody, can also set $EXCEPTION_NOTIFY to false
ExceptionNotifier.sender_address = $EXCEPTION_EMAIL_ADDRESS
ExceptionNotifier.email_prefix = "[EOL] "

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

if ENV['BLEAK']
  require 'bleak_house'
end

$CACHE = Rails.cache

# Taken right from http://tinyurl.com/3xzen6z
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    if forked # We're in smart spawning mode.
      $CACHE = Rails.cache.clone
    else
      # We're in conservative spawning mode. We don't need to do anything.
    end
  end
end


# load the system configuration
require File.dirname(__FILE__) + '/system' if File.file?(File.dirname(__FILE__) + '/system.rb')
