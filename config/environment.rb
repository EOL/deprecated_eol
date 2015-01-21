# Load the rails application
require File.expand_path('../application', __FILE__)
require File.expand_path('../../lib/initializer_additions', __FILE__)

# TODO - we should probably have a bunch of non-environment-specific defaults
# here, rather than in EVERY environment file. :\ I'm going to start the trend:

# Donate config just needs to be defined (will be skipped if blank):
Rails.configuration.donate_header_url = nil
Rails.configuration.donate_footer_url = nil
Rails.configuration.skip_url_validations = false

InitializerAdditions.add("environments/local")
Eol::Application.initialize!

Rails.configuration.use_secure_acceptance = ENV["EOL_USE_SECURE_ACCEPTANCE"] == "true"
Rails.configuration.secure_acceptance = {
  email: ENV["EOL_SEC_ACCEPT_EMAIL"],
  org_id: ENV["EOL_SEC_ACCEPT_ORG_ID"],
  merchant_id: ENV["EOL_SEC_ACCEPT_MERCHANT_ID"],
  endpoint: ENV["EOL_SEC_ACCEPT_ENDPOINT"],
  profile_id: ENV["EOL_SEC_ACCEPT_PROFILE_ID"], # Must be 7 chrs.  Exactly.
  access_key: ENV["EOL_SEC_ACCEPT_ACCESS_KEY"],
  # NOTE - this is only good until Dec 2015
  secret_key: ENV["EOL_SEC_ACCEPT_SECRET_KEY"]
}
# None, by default, but defined:
Rails.configuration.google_site_verification_keys = []
Rails.configuration.donate_header_url =
  ENV["EOL_DONATE_HEADER_URL"]
Rails.configuration.donate_footer_url =
  ENV["EOL_DONATE_DONATE_FOOTER_URL"]
Rails.configuration.inat_collection_url =
  ENV["EOL_DONATE_INAT_COLLECTION_URL"]

Eol::Application.configure do
  config.after_initialize do
    $SPECIES_PAGES_GROUP_EMAIL_ADDRESS =
      ENV["EOL_SPECIES_PAGES_GROUP_EMAIL_ADDRESS"]
    $SUPPORT_EMAIL_ADDRESS = ENV["EOL_SUPPORT_EMAIL_ADDRESS"]
    $ERROR_EMAIL_ADDRESS = ENV["EOL_ERROR_EMAIL_ADDRESS"]
    $EDUCATION_EMAIL = ENV["EOL_EDUCATION_EMAIL"]
    $NO_REPLY_EMAIL_ADDRESS = ENV["EOL_NO_REPLY_EMAIL_ADDRESS"]
    $GOOGLE_MAP_API_KEY = ENV["EOL_GOOGLE_MAP_API_KEY"]
    $MAP_DATA_SERVER_ENDPOINT = ENV["EOL_MAP_DATA_SERVER_ENDPOINT"]
    $MAP_TILE_SERVER_1 = ENV["EOL_MAP_TILE_SERVER_1"]
    $MAP_TILE_SERVER_2 = ENV["EOL_MAP_TILE_SERVER_2"]
    $MAP_TILE_SERVER_3 = ENV["EOL_MAP_TILE_SERVER_3"]
    $MAP_TILE_SERVER_4 = ENV["EOL_MAP_TILE_SERVER_4"]
    $TWITTER_USERNAME = ENV["EOL_TWITTER_USERNAME"]
    $FLICKR_API_KEY = ENV["EOL_FLICKR_API_KEY"]
    $FLICKR_USER_ID = ENV["EOL_FLICKR_USER_ID"]
    $FLICKR_SECRET = ENV["EOL_FLICKR_SECRET"]
    $FLICKR_FROB = ENV["EOL_FLICKR_FROB"]
    $FLICKR_TOKEN = ENV["EOL_FLICKR_TOKEN"]
    CHINESE_PRONUNCIATION_API_PREFIX =
      ENV["EOL_CHINESE_PRONUNCIATION_API_PREFIX"]
  end
end
