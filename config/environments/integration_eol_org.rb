#============================================================
#              integration_eol_org.rb
# Location specific settings for the Integration environment
#
# Settings specified here will take precedence over those in 
# config/environment.rb and integration.rb 
#============================================================

# Uncomment the cache_store option desired.  The default is memcached
Rails.configuration.cache_store = :mem_cache_store, '127.0.0.1:11211'
# config.cache_store = :file_store, "/data/cache"


# Content servers are where the images and video live
#config.action_controller.asset_host = "http://content0.eol.org"
$CONTENT_SERVERS = ['http://content.eol.org/']
$CONTENT_SERVER_CONTENT_PATH = "content" # do not enter leading or trailing slashes
$CONTENT_SERVER_RESOURCES_PATH = "/resources/"
$CONTENT_SERVER_AGENT_LOGOS_PATH = "/content_partners/"
$SPECIES_IMAGE_FORMAT = "jpg" # the extension of all species images on the content server


# Static servers (asset_hosts) are where stylesheets and javascripts are 
# served from
Rails.configuration.action_controller[:asset_host] = "http://staticint.eol.org"
# StaticEolAssetHost.asset_host_proc


# URL to use for uploading logos from the app server to the content master
$WEB_SERVICE_BASE_URL="http://10.19.19.226/php_code/applications/content_server/service.php?"

# The email addresses
$CONTENT_PARTNER_REGISTRY_EMAIL_ADDRESS="affiliate@eol.org"
$WEBSITE_EMAIL_FROM_ADDRESS="no-reply@eol.org"
ExceptionNotifier.sender_address =%("EOL Application Error" <no-reply@eol.org>)


# URLs to test - suspect this isn't being used any more as the original
# list contained mainly URLS that are defunct
$TEST_URLS = %w{http://www.eol.org http://eol.org}
