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

# Note this defaults to false (because it's nil):
Rails.configuration.use_secure_acceptance = ENV["EOL_USE_SECURE_ACCEPTANCE"] == "true"
if Rails.configuration.use_secure_acceptance
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
end

Rails.configuration.asset_host = ENV["EOL_ASSET_HOST"] || 'localhost'
# If you put leading and trailing slashes here you get double slashes in the
# URLs, which work fine but aren't right
Rails.configuration.content_path = "content"
# The extension of all species images on the content server; avoids storing
# another three characters in the data_objects table (which is a hundred million
# rows)
Rails.configuration.species_img_fmt = "jpg"

# None, by default, but defined:
Rails.configuration.google_site_verification_keys = []
Rails.configuration.donate_header_url =
  ENV["EOL_DONATE_HEADER_URL"] || ''
Rails.configuration.donate_footer_url =
  ENV["EOL_DONATE_DONATE_FOOTER_URL"] || ''
Rails.configuration.inat_collection_url =
  ENV["EOL_DONATE_INAT_COLLECTION_URL"] || ''

# Solr Stuff:
Rails.configuration.solr_relationships_page_size =
  ENV["SOLR_RELATIONSHIPS_PAGE_SIZE"] || 1000

Rails.configuration.google_maps_key = ENV["EOL_GOOGLE_MAP_API_KEY"] || ''

Eol::Application.configure do
  config.after_initialize do
    no_email = "someguy@some.whe.re"
    $SPECIES_PAGES_GROUP_EMAIL_ADDRESS =
      ENV["EOL_SPECIES_PAGES_GROUP_EMAIL_ADDRESS"] || no_email
    $SUPPORT_EMAIL_ADDRESS = ENV["EOL_SUPPORT_EMAIL_ADDRESS"] || no_email
    $ERROR_EMAIL_ADDRESS = ENV["EOL_ERROR_EMAIL_ADDRESS"] || no_email
    $EDUCATION_EMAIL = ENV["EOL_EDUCATION_EMAIL"] || no_email
    $NO_REPLY_EMAIL_ADDRESS = ENV["EOL_NO_REPLY_EMAIL_ADDRESS"] || no_email
    $TWITTER_USERNAME = ENV["EOL_TWITTER_USERNAME"] || ''
    $FLICKR_API_KEY = ENV["EOL_FLICKR_API_KEY"] ||
      'cafecafecafecafecafecafecafecafe'
    $FLICKR_USER_ID = ENV["EOL_FLICKR_USER_ID"] || '12345678@A12'
    $FLICKR_SECRET = ENV["EOL_FLICKR_SECRET"] || 'cafecafecafecafe'
    $FLICKR_FROB = ENV["EOL_FLICKR_FROB"] ||
      '12345678901234567-cafecafecafecafe-12345678'
    $FLICKR_TOKEN = ENV["EOL_FLICKR_TOKEN"] ||
      '12345678901234567-cafecafecafecafe'
  end
end
