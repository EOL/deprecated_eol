source "https://rubygems.org"

# TODO: - convert all of these specifc versions to use the first two digits.

group :development, :test, :staging_dev, :test_dev, :bocce_demo_dev do
  # TODO: - update capistrano
  gem "capistrano", "2.13.5" # For deploys.
  # For deploys. Note we've customized it...
  gem "capistrano-unicorn-pleary", "=0.1.6.1"
  gem "rvm-capistrano", "1.2.7" # For deploys.
  # We use this *extensively* in testing for user-like behavior. Learn this.
  gem "capybara", "1.1.3"
  # This allows tasks to run in the background, like Solr.
  gem "daemons", "1.1.9"
  # We use this *extensively* in testing to create "real" models. Learn this.
  gem "factory_girl_rails"
  # We use this for creating "realistic" names for testing / bootstrapping.
  gem "faker", "1.2.0"
  # This improves formatting of specs. Not including a version because updates
  # are probably good.
  gem "fuubar"
  gem "haml-rails" # Just for rails generators.
  # Handles command-line arguments. We currently only use this for Solr tasks.
  gem "optiflag", "0.7"
  gem "rspec-rails"
  gem "ruby-prof", "0.11.2" # Used to measure performance.
  # TODO: - update nokogiri
  # Yeah, I know this has given us grief in the past.  :\ Trying things out, is
  # all.
  gem "nokogiri", "1.5.5"
  gem "pre-commit", "~> 0.17"
end

# Essentially, this "group" is for everything except production:
group :development, :test, :staging, :staging_dev, :test_dev, :bocce_demo,
      :bocce_demo_dev do
  gem "debugger" # Clearly, this is for debugging.  :)
end

group :staging, :bocce_demo do
  gem "hipchat" # We use this for deploy notifications.
end

group :development, :staging_dev, :staging_dev_cache, :bocce_demo_dev,
      :test_dev do
  # TODO: - do we still need this?  I doubt it; remove it, see what breaks. :)
  gem "webrick", "1.3.1"
end

# NOT versioning these, since they really are for development (and test) only:
group :test, :development do
  gem "launchy" # Allows save_and_open_page in specs, very, very handy!
  # rails console has additional commands: show-models, show-routes --grep use
  gem "pry-rails"
  # Better debugging. Raise an error in pry console and use cd-cause to get to
  # the error point, use edit to launch your editor, then try-again to ...
  # uhh... try again. Use Ctrl-\ to break running code. run rescue rspec to
  # get specs to pry errors automatically (but note try-again doesn't work from
  # rspec). rescue rails server also uses pry.
  gem "pry-rescue"
  gem "pry-stack_explorer", require: false
  gem "terminal-notifier-guard" # Allows for OS X notifications about errors
  # Used by Better Errors to give lots more information about errors in the
  # browser.
  gem "binding_of_caller"
end

# NOTE - if you are having trouble installing these, you can either:
#        1) install qt (at the time of this writing, you must install the HEAD
#           version: brew install qt --HEAD )
#        2) don't bother with these gems (they are only needed for acceptance
#           tests): bundle --without=acceptance

group :acceptance do
  # Used for "acceptance testing", includes javascript testing.
  gem "capybara-webkit"
end

group :development do
  # NEVER EVER *EVER* run this in production. Ever. Don't. It will be
  # immediately obvious what it does in dev.
  gem "better_errors"
end

group :test do
  # TODO: - update webmock
  # Mock calls to remote APIs, like Open Authentication.
  gem "webmock", "1.8.11", require: false
  # Adds #with_tag for tests. Requires nokogiri.
  gem "rspec-html-matchers", "0.4.3"
  gem "simplecov", "~> 0.7.1", require: false
end

# IMPORTANT NOTE - any time you update Rails, you really need to double-check
# our monkey-patches in lib/select_with_preload_include (in addition to the
# usual tests).
gem "rails", "~> 4.0"

gem "actionpack-page_caching"
gem "active_type", "~> 0.2" # Facilitates context-driven model subclasses.
# Used for drag-and-drop reordering of KnownUri instances. ...We could be making
# wider use of this.
gem "acts_as_list", "0.3.0"
# We use this for a few of our tree-like models, such as TocItem and
# CollectionType.
gem "acts_as_tree_rails3", "0.1.0"
# "used for generation of scientific names with ranks on the species page"
gem "biodiversity", "3.1.2"
# Used by identity_cache to speed up the creation of hash keys.
gem "cityhash"
# We use this in many places, such as creating data objects, to allow rich text
# editing.
gem "ckeditor"
# IMPORTANT NOTE - any time you update CPK, you really need to double-check our
# monkey-patches in lib/select_with_preload_include (in addition to the usual
# tests). We have lots of tables with CPK, so we need this.
gem "composite_primary_keys", "~> 6"
# Used for cached counts of associations, better than rails default.
gem "counter_culture", "0.1.19"
# Memcached handler. This is what handles ALL of our caching, so learn this.
gem "dalli", "2.6.4"
# Octopus helps handle several databases at the same time, but we had to
# customize it for our needs:
gem "ar-octopus"
# For testing emails within RSpec.
gem "email_spec", "1.4.0"
# provides several HTML/URI/shell escaping functions - TODO: - I don't think we
# need this?
gem "escape"
gem "ezcrypto" # TODO: - remove this, I don"t think we use it.
# http://www.rubysec.com/advisories/OSVDB-96425/
# TODO: - this can be removed once we update redis/resque.
gem "redis-namespace", "1.2.2"
# Used ONLY for CyberSource donations. ...but I'm not sure how best to group
# this gem otherwise.
gem "ruby-hmac", "0.4.0"
# Used to cache objects in a robust way:
gem "identity_cache"
# TODO: - remove this, Rails has something like this baked in.
# I forget what it's called.
gem "indifferent-variable-hash", "0.1.0"
gem "invert"  # A quick way to array.sort.reverse.
gem "jquery-rails", "2.1.3" # Of course, this helps almost all of our JS.
gem "json", "1.8.1" # For APIs that want to return JSON.
# For creating UUIDs that are unique to the machine that makes them.
gem "macaddr"
# For handling the many differnt types of files to serve, such as videos.
gem "mime-types", "1.25"
gem "mysql2", "0.3.14" # This is our database. You might want this.
# For gathering tons of awesome stats about the site
gem "newrelic_rpm", "~> 3.9"
# TODO: - update oauth ... do we even still use v1?
gem "oauth", "0.4.7" # Logging in via Facebook and Twitter, older version.
gem "oauth2", "0.8.0" # Logging in via Facebook and Twitter
# Uploading files, such as icons for users and collections.
gem "paperclip"
# Upgrading from Rails 3; this was easier:
gem "protected_attributes"
gem "rails_autolink", "1.1.5" # Adding links to user-entered text.
# Autocomplete Ajax.
gem "rails4-autocomplete"
# TODO: - update recaptcha.
# An empathy test to see if you're a human, when creating an account.
gem "recaptcha", "0.3.4", require: "recaptcha/rails"
# TODO: - update resque. (and redis)
# For background jobs, like email notifications and classification curation
gem "resque", "1.23.0", require: "resque/server"
gem "sanitize", "2.0.3" # To clean up user-enter HTML.
gem "sass-rails"
# TODO: - update sparql-client
gem "sparql-client", "1.0.4.1" # For the data tab
gem "statsd-ruby", "1.2.1" # For recording various stats around the site.
gem "uglifier", "2.3.1" # For smaller JS when assets are compiled
# TODO: - update unicorn.
gem "unicorn", "4.4.0" # This is our webserver
# TODO: - update uuid
gem "uuid", "2.3.5" # Used when creating data objects
# TODO: - update will_paginate
gem "will_paginate", "~> 3.0" # Used ALL OVER THE SITE for pagination.
gem "nunes", "0.3.0"  # This makes it easier to handle statsd
gem "execjs", "2.0.2"  # needed to run rake tasks in cron
