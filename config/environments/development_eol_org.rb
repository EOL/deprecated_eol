$KINGDOM_IDs = ['1']

$CONTENT_SERVERS = ['http://content70.eol.org/','http://content71.eol.org/','http://content72.eol.org/','http://content73.eol.org/','http://content74.eol.org/','http://content75.eol.org/']

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
:address => "rubus.eol.org",
:port => 25,
:domain => "eol.org",
}