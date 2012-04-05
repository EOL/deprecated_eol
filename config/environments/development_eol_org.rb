$KINGDOM_IDs = ['1']

$CONTENT_SERVERS = ['http://content70.eol.org/','http://content71.eol.org/','http://content72.eol.org/','http://content73.eol.org/','http://content74.eol.org/','http://content75.eol.org/']

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
:address => "rubus.eol.org",
:port => 25,
:domain => "eol.org",
}

# OAuth API keys for EOL Development Applications
$FACEBOOK_APP_ID = "336932289696842"
$FACEBOOK_CONSUMER_KEY = $FACEBOOK_APP_ID
$FACEBOOK_CONSUMER_SECRET = "b9b40823a05488d192f1e7b10f773f6c"
$GOOGLE_CONSUMER_KEY = "121814272159.apps.googleusercontent.com"
$GOOGLE_CONSUMER_SECRET = "Uvt5bW5Yrxwc7q1CrxyJxWRT"
$TWITTER_CONSUMER_KEY = "Wg7TcGujZZ442dQ6QA5Fw"
$TWITTER_CONSUMER_SECRET = "FQdkpVFNkARoqHqV2X2lC84YOS8Wyu8DSZ1ojnxGx4"
$YAHOO_CONSUMER_KEY = "dj0yJmk9T0JCSDFVd04wdmFLJmQ9WVdrOVprMWFTV3hHTlRBbWNHbzlOelEyTXpNNE56WXkmcz1jb25zdW1lcnNlY3JldCZ4PTBj"
$YAHOO_CONSUMER_SECRET = "f2bc8315b107ee45863a4c04defa27ae46431963"
$YAHOO_APP_ID = "fMZIlF50"
