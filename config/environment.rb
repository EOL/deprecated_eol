# Load the rails application
require File.expand_path('../application', __FILE__)
require File.expand_path('../../lib/initializer_additions', __FILE__)

# TODO - we should probably have a bunch of non-environment-specific defaults
# here, rather than in EVERY environment file. :\ I'm going to start the trend:

# Donate config just needs to be defined (will be skipped if blank):
Rails.configuration.donate_header_url = nil
Rails.configuration.donate_footer_url = nil
Rails.configuration.skip_url_validations = false

InitializerAdditions.add("environment_eol_org")
InitializerAdditions.add("environments/local")
Eol::Application.initialize!
Haml::Template.options[:escape_attrbs] = false
Haml::Template.options[:escape_html] = false

# TODO - Set defaults for some horrible global variables that really
# needed to get cleaned up.  Currently most get overriden in appropriate
# environment files, but we need defaults to get tests working without
# getting the eol-private stuff.                                                                                                                                                                                              

$DEFAULT_EMAIL_ADDRESS = "noreply@eol.org"
$SPECIES_PAGES_GROUP_EMAIL_ADDRESS = $DEFAULT_EMAIL_ADDRESS
$SUPPORT_EMAIL_ADDRESS = $DEFAULT_EMAIL_ADDRESS
$ERROR_EMAIL_ADDRESS = $DEFAULT_EMAIL_ADDRESS
$EDUCATION_EMAIL = $DEFAULT_EMAIL_ADDRESS
$NO_REPLY_EMAIL_ADDRESS = $DEFAULT_EMAIL_ADDRESS

$FLICKR_API_KEY = 'cafecafecafecafecafecafecafecafe'
$FLICKR_USER_ID = '12345678@A12'
$FLICKR_SECRET = 'cafecafecafecafe'
$FLICKR_FROB = '12345678901234567-cafecafecafecafe-12345678'
$FLICKR_TOKEN = '12345678901234567-cafecafecafecafe'
