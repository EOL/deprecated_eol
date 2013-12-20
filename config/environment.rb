# Load the rails application
require File.expand_path('../application', __FILE__)
require File.expand_path('../../lib/initializer_additions', __FILE__)

InitializerAdditions.add("environment_eol_org")
InitializerAdditions.add("environments/local")
Eol::Application.initialize!
