# Load the rails application
require File.expand_path('../application', __FILE__)
require File.expand_path('../../lib/initializer_additions', __FILE__)

# TODO - we should probably have a bunch of non-environment-specific defaults
# here, rather than in EVERY environment file. :\ I'm going to start the trend:

# Donate config just needs to be defined (will be skipped if blank):
Rails.configuration.donate_header_url = nil
Rails.configuration.donate_footer_url = nil


InitializerAdditions.add("environment_eol_org")
InitializerAdditions.add("environments/local")
Eol::Application.initialize!
