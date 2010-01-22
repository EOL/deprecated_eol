$KINGDOM_IDs = ['1']

ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
:address => "rubus.eol.org",
:port => 25,
:domain => "eol.org",
}