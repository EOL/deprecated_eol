# So, the new-fangled way to do configuration in Rails is Rails.configuration.WHATEVER.  ...So let's do that. It's better than
# friggin' globals.  That said, we may want to adopt the simple, popular, SimpleConfig:
# https://github.com/lukeredpath/simpleconfig

#Server's IP address
Rails.configuration.site_domain = "eol.org" #domain name for url links communicated outside, for example for emails

# If you're testing a new feature, they will be asked to go here to provide feedback:
Rails.configuration.beta_test_feedback_link = 'https://www.surveymonkey.com/s/9FDTDQP'

# Collection configu settings:

Rails.configuration.inat_project_prefix = "http://eol.org/collections/"

# TAXON DATA configuration settings:

Rails.configuration.uri_prefix = 'http://eol.org/schema/'
Rails.configuration.uri_term_prefix = "#{Rails.configuration.uri_prefix}terms/"
Rails.configuration.uri_reference_prefix = "#{Rails.configuration.uri_prefix}reference/"
Rails.configuration.uri_resources_prefix = "#{Rails.configuration.uri_prefix}resources/"
Rails.configuration.uri_true = "#{Rails.configuration.uri_term_prefix}true"
Rails.configuration.uri_uses_measurement = "#{Rails.configuration.uri_prefix}uses_measurement"
Rails.configuration.uri_allowed_val = "#{Rails.configuration.uri_prefix}allowedValue"
Rails.configuration.uri_allowed_unit = "#{Rails.configuration.uri_prefix}allowedUnit"
Rails.configuration.uri_supplier = "#{Rails.configuration.uri_term_prefix}supplier"
Rails.configuration.uri_target_occurence = "#{Rails.configuration.uri_prefix}targetOccurrenceID"
Rails.configuration.uri_reference = "#{Rails.configuration.uri_prefix}reference/Reference"
Rails.configuration.uri_reference_id = "#{Rails.configuration.uri_prefix}reference/referenceID"
Rails.configuration.uri_association_id = "#{Rails.configuration.uri_prefix}associationID"
Rails.configuration.uri_association_type = "#{Rails.configuration.uri_prefix}associationType"
Rails.configuration.uri_measurement_of_taxon = "#{Rails.configuration.uri_prefix}measurementOfTaxon"
Rails.configuration.uri_parent_measurement_id = "#{Rails.configuration.uri_prefix}parentMeasurementID"
# DarwinCore
Rails.configuration.uri_dwc = "http://rs.tdwg.org/dwc/terms/"
Rails.configuration.uri_data_measurement = "#{Rails.configuration.uri_dwc}MeasurementOrFact"
Rails.configuration.uri_measurement_unit = "#{Rails.configuration.uri_dwc}measurementUnit"
# OBO
Rails.configuration.uri_obo = "http://purl.obolibrary.org/obo/"
# Dublin Core
Rails.configuration.uri_dc = "http://purl.org/dc/terms/"
Rails.configuration.uri_license = "#{Rails.configuration.uri_dc}license"
Rails.configuration.uri_source = "#{Rails.configuration.uri_dc}source"
Rails.configuration.uri_citation = "#{Rails.configuration.uri_dc}bibliographicCitation"
# OWL
Rails.configuration.uri_owl = 'http://www.w3.org/2002/07/owl#'
Rails.configuration.uri_equivalent_property = "#{Rails.configuration.uri_owl}equivalentProperty"
Rails.configuration.uri_inverse = "#{Rails.configuration.uri_owl}inverseOf"


Rails.configuration.uri_prefix_user_added_data = "http://eol.org/pages/" # TODO - this should be a polymorphic hash, ie:
                                # { taxon_concept: "http://eol.org/pages/", data_object: "http://eol.org/data_objects/" } ...etc...
Rails.configuration.uri_prefix_association = "#{Rails.configuration.uri_prefix}Association"
Rails.configuration.user_added_data_graph = "http://eol.org/user_data/"
Rails.configuration.known_uri_graph = "http://eol.org/known_uris"
Rails.configuration.known_taxon_uri_re = /^http:\/\/(www\.)?eol\.org\/pages\/(\d+)/i # Note this stops looking past the id.
Rails.configuration.optional_reference_uris = { # Be careful changing these...  :)
  identifier: "http://purl.org/dc/terms/identifier",
  publicationType: "http://eol.org/schema/reference/publicationType",
  full_reference: "http://eol.org/schema/reference/full_reference",
  primaryTitle: "http://eol.org/schema/reference/primaryTitle",
  title: "http://purl.org/dc/terms/title",
  pages: "http://purl.org/ontology/bibo/pages",
  pageStart: "http://purl.org/ontology/bibo/pageStart",
  pageEnd: "http://purl.org/ontology/bibo/pageEnd",
  volume: "http://purl.org/ontology/bibo/volume",
  edition: "http://purl.org/ontology/bibo/edition",
  publisher: "http://purl.org/dc/terms/publisher",
  authorList: "http://purl.org/ontology/bibo/authorList",
  editorList: "http://purl.org/ontology/bibo/editorList",
  created: "http://purl.org/dc/terms/created",
  language: "http://purl.org/dc/terms/language",
  uri: "http://purl.org/ontology/bibo/uri",
  doi: "http://purl.org/ontology/bibo/doi",
  localityName: "http://schemas.talis.com/2005/address/schema#localityName"
}

Rails.configuration.data_search_file_rel_path = '/uploads/data_search_files/:id.csv'
Rails.configuration.data_search_file_full_path = "#{Rails.public_path}#{Rails.configuration.data_search_file_rel_path}"

Rails.configuration.hosted_dataset_path = 'http://localhost/eol_php_code/applications/content_server/datasets/'

Rails.configuration.local_services = false


# -------------------------------------------------------------------------
# OLD STUFF...          PLEASE DON'T DO THIS ANYMORE.  :|

# Moving all the (stupid) globals we used to have in the environment.rb file here.  But, really, we should find an
# even better solution than this.

# As of this writing, this is used for two things:
#   1) Avoid harmful migrations in production using #raise_error_if_in_production, and
#   2) Log errors to NewRelic if we're in production (or on staging).
$PRODUCTION_MODE = Rails.env.production? || Rails.env.staging? || Rails.env.sync?

# How many images we want to show, at maximum, for a given page.  This number should be lower than the maximum
# number of images created in the cached_images tables.  (EOL presently sets cached_image limits at 500.)
$IMAGE_LIMIT = 200

# THIS IS WHERE ALL THE IMAGES/VIDEOS LIVE:
$CONTENT_SERVER = 'http://localhost/'
$SINGLE_DOMAIN_CONTENT_SERVER = 'http://localhost/'
$CONTENT_SERVER_CONTENT_PATH = "content" # if you put leading and trailing slashes here you get double slashes in the URLs, which work fine but aren't right
$CONTENT_SERVER_RESOURCES_PATH = "/resources/"
$CONTENT_SERVER_AGENT_LOGOS_PATH = "/content_partners/"
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
$ENABLED_SOCIAL_PLUGINS = [ :facebook, :google, :twitter, :yahoo ] # Enable open authentication and social sharing on the site e.g. Facebook Like button

# DATA LOGGING CONFIGURATION
$ENABLE_DATA_LOGGING = true # set to true to enable data usage and search term logging in logging database

# ERROR HANDLING CONFIGURATION
$EXCEPTION_NOTIFY = false # set to false to not be notified of exceptions via email in production mode (set email addresses below)
$ERROR_LOGGING = true # set to true to record uncaught application errors in sql database file
$EXCEPTION_EMAIL_ADDRESS = %("EOL Application Error" <no-reply@example.comma>)
$IGNORED_EXCEPTIONS = ["CGI::Session::CookieStore::TamperedWithCookie","taxa id not supplied"] # array of exceptions to ignore when logging or notifying
$IGNORED_EXCEPTION_CLASSES = [ 'ActionController::RoutingError', 'EOL::Exceptions::MustBeLoggedIn', 'EOL::Exceptions::SecurityViolation' ] # array of exceptions to ignore when logging or notifying

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
$LOGO_UPLOAD_DIRECTORY = "#{Rails.public_path}/uploads/images/collection_icons/:class_:id.:extension"  # directory to place uploaded content partner logos from CP registry, content server needs SFTP access to this folder (logos are not server out of this area)
$LOGO_UPLOAD_MAX_SIZE = 5242880 # 5 megabytes
$DATASET_UPLOAD_PATH = "/uploads/datasets/"  # directory to place uploaded content partner datasets, content server needs SFTP access to this folder
$DATASET_UPLOAD_DIRECTORY = "#{Rails.public_path}/uploads/datasets/:id.:extension"  # directory to place uploaded content partner datasets, content server needs SFTP access to this folder

$CONTENT_UPLOAD_PATH = "/uploads/"  # directory to place uploaded content files, content server needs SFTP access to this folder
$CONTENT_UPLOAD_DIRECTORY = "#{Rails.public_path}/uploads/:id.:extension"  # directory to place uploaded content

# NEWS ITEMS ON HOME PAGE CONFIGURATION
$NEWS_ITEMS_HOMEPAGE_MAX_DISPLAY = 5 # the maximum number of news items to show on the home page at any time
$NEWS_ITEMS_TIMEOUT_HOMEPAGE_WEEKS = 8 # the number of weeks before a news item automatically disappears from the home page (determined by the "display date")

# WEBSERVICE CONFIGURATION
$WEB_SERVICE_TIMEOUT_SECONDS = 60 # how many seconds to wait when calling a webservice before timing out and returning nil
$LOG_WEB_SERVICE_EXECUTION_TIME = false # if set to false, then execution times for web service calls will not be recorded
$WEB_SERVICE_BASE_URL = '' # web service is used for importing content partners' data

### These next few values are declared in the eol:site_configurations table. They are also declared here
### beacuse when we switch to SI we will not be able to edit the database and need to be able to tweak the
### environment file to possibly override the values in the DB
# $REFERENCE_PARSING_ENABLED = false
# $REFERENCE_PARSER_ENDPOINT = **the URL of the reference parsing script**
# $REFERENCE_PARSER_PID = **the email address of the crossref user account**

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

$NEWS_ON_HOME_PAGE = 6
$ACTIVITIES_ON_HOME_PAGE = 6
$HOMEPAGE_ACTIVITY_LOG_CACHE_TIME = 10  # minutes
$HOMEPAGE_NEWS_CACHE_TIME = 10  # minutes
$HOMEPAGE_MARCH_RICHNESS_THRESHOLD = 0.5

$ENABLE_TRANSLATION_LOGS = false # This is expensive; DON'T do it by default!

# Default values for some footer elements:
$EOL_TWITTER_ACCOUNT    = "http://twitter.com/#!/EOL"
$EOL_FACEBOOK_ACCOUNT   = "http://www.facebook.com/encyclopediaoflife"
$EOL_FLICKR_ACCOUNT     = "http://www.flickr.com/groups/encyclopedia_of_life/"
$EOL_YOUTUBE_ACCOUNT    = "http://www.youtube.com/user/EncyclopediaOfLife/"
$EOL_PINTEREST_ACCOUNT  = "http://pinterest.com/eoflife/"
$EOL_VIMEO_ACCOUNT      = "http://vimeo.com/groups/encyclopediaoflife"
$EOL_FLIPBOARD_ACCOUNT  = "http://flip.it/eol"
$EOL_GOOGLE_PLUS_ACCOUNT  = "//plus.google.com/+encyclopediaoflife?prsrc=3"

$CURATOR_COMMUNITY_NAME = 'EOL Curators'
$CURATOR_COMMUNITY_DESC = 'This is a special community intended for EOL curators to discuss matters related to curation on the Encylopedia of Life.'

$VIRTUOSO_USER = 'dba'
$VIRTUOSO_PW = 'dba'
$VIRTUOSO_SPARQL_ENDPOINT_URI = 'http://localhost:8890/sparql'
$VIRTUOSO_UPLOAD_URI = 'http://localhost:8890/DAV/home/dba/upload'
$VIRTUOSO_FACET_BROWSER_URI_PREFIX = 'http://localhost:8890/describe/?url='

# Recaptcha Keys
ENV['RECAPTCHA_PUBLIC_KEY'] = ''
ENV['RECAPTCHA_PRIVATE_KEY'] = ''

EOL_CODEBASE_MASTER_VERSION = "2.2"

# NOTE - don't put a value in this, and don't change this paragraph of code, so that capistrano can automate it:

# Assign it during deployment with capistrano
ENV['APP_VERSION'] = ''
