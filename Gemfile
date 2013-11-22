source 'https://rubygems.org'

group :development, :test, :staging_dev, :test_dev, :bocce_demo_dev do
  gem 'capistrano', '2.13.5' # For deploys.
  gem 'capistrano-unicorn-pleary', '=0.1.6.1' # For deploys. Note we've customized it...
  gem 'rvm-capistrano', '1.2.7' # For deploys.
  gem 'capybara', '1.1.3' # We use this *extensively* in testing for user-like behavior. Learn this.
  gem 'daemons', '1.1.9' # This allows tasks to run in the background, like Solr.
  gem 'factory_girl_rails', '4.1.0' # We use this *extensively* in testing to create "real" models. Learn this.
  gem 'faker', '1.1.2' # We use this for creating "realistic" names for testing / bootstrapping.
  gem 'haml-rails' # Just for rails generators.
  gem 'optiflag', '0.7' # Handles command-line arguments. We currently only use this for Solr tasks.
  gem 'rspec-rails', '2.14' # This is what we use for testing. Learn it.
  gem 'ruby-prof', '0.11.2' # Used to measure performance.
  gem 'nokogiri', '1.5.5' # Yeah, I know this has given us grief in the past.  :\ Trying things out, is all.
end

# Essentially, this "group" is for everything except production:
group :development, :test, :staging, :staging_dev, :test_dev, :bocce_demo, :bocce_demo_dev do
  gem 'debugger' # Clearly, this is for debugging.  :)
end

group :staging, :bocce_demo do
  gem 'hipchat' # We use this for deploy notifications.
end

group :development, :staging_dev, :staging_dev_cache, :bocce_demo_dev, :test_dev do
  gem 'webrick', '1.3.1' # TODO - do we still need this?  I doubt it.
end

# NOT versioning these, since they really are for development (and test) only:
group :test, :development do
  gem 'guard-zeus', require: false # Auto-testing with zeus (IFF you have it installed)
  gem 'guard-bundler', require: false # automatically install/update your gem bundle when needed
  gem 'guard-rspec', require: false # Auto-testing
  gem 'launchy' # Allows save_and_open_page in specs, very, very handy!
  gem 'pry-rails' # rails console has additional commands: show-models, show-routes --grep use
  gem 'pry-rescue' # Better debugging. Raise an error in pry console and use cd-cause to get to the error point, use edit
    # to launch your editor, then try-again to ... uhh... try again. Use Ctrl-\ to break running code. run rescue rspec to
    # get specs to pry errors automatically (but note try-again doesn't work from rspec). rescue rails server also uses pry.
  gem 'pry-stack_explorer', require: false
  gem 'terminal-notifier-guard' # Allows for OS X notifications about errors
  gem 'binding_of_caller' # Used by Better Errors to give lots more information about errors in the browser.

end

# NOTE - if you are having trouble installing these, you can either:
#        1) install qt (at the time of this writing, you must install the HEAD version: brew install qt --HEAD )
#        2) don't bother with these gems (they are only needed for acceptance tests): bundle --without=acceptance
group :acceptance do
  gem 'capybara-webkit' # Used for "acceptance testing", includes javascript testing.
end

group :development do
  gem 'better_errors' # NEVER EVER *EVER* run this in production. Ever. Don't. It will be immediately obvious what it does in dev.
end

group :test do
  gem 'webmock', '1.8.11' # Mock calls to remote APIs, like Open Authentication.
  gem 'rspec-html-matchers', '0.3.5' # Adds #with_tag for tests. Requires nokogiri.
end

group :assets do
  gem 'turbo-sprockets-rails3', '0.3.4' # This is supposed to minimize the re-building of assets. AFAICT, it isn't working for us.
end

gem 'rails', '3.2.15'

gem 'acts_as_list', '0.2.0' # Used for drag-and-drop reordering of KnownUri instances. ...We could be making wider use of this.
gem 'acts_as_tree_rails3', '0.1.0' # We use this for a few of our tree-like models, such as TocItem and CollectionType.
gem 'biodiversity19', '1.1.3' # TODO - I don't think we use this. ...even if we do, it's deprecated, replace it.
gem 'cityhash', '0.8.1' # Used by identity_cache to speed up the creation of hash keys.
gem 'ckeditor', '3.7.3' # We use this in many places, such as creating data objects, to allow rich text editing.
gem 'coffee-rails', '3.2.2' # TODO - do we actually use this? If so, it helps make simplified JS, for Ajax responses.
gem 'composite_primary_keys', '5.0.13' # We have lots of tables with CPK, so we need this.
gem 'dalli', '2.6.4' # Memcached handler. This is what handles ALL of our caching, so learn this.
# Octopus helps handle several databases at the same time, but we had to customize it for our needs:
gem 'ar-octopus', '0.4.0', :git => "git://github.com/pleary/octopus.git", :branch => "0.4.0", :require => "octopus" 
gem 'email_spec', '1.4.0' # For testing emails within RSpec.
gem 'escape', '0.0.4' # provides several HTML/URI/shell escaping functions - TODO - I don't think we need this?
gem 'ezcrypto', '0.7.2' # TODO - remove this, I don't think we use it.
gem 'haml', '4.0.4' # This is how we handle ALL of our HTML, you need to learn this.
gem 'identity_cache', '0.0.4' # Used to cache objects in a robust way.
gem 'indifferent-variable-hash', '0.1.0' # TODO - remove this, Rails has something like this baked in. I forget what it's called.
gem 'invert', '0.1.0'  # A quick way to array.sort.reverse.
gem 'jquery-rails', '2.1.3' # Of course, this helps almost all of our JS.
gem 'json', '1.8.1' # For APIs that want to return JSON.
gem 'macaddr', '1.6.1' # For creating UUIDs that are unique to the machine that makes them.
gem 'mime-types', '1.19' # For handling the many differnt types of files to serve, such as videos.
gem 'mysql2', '0.3.14' # This is our database. You might want this.
gem 'newrelic_rpm', '>3.5.3' # For gathering tons of awesome stats about the site
gem 'oauth', '0.4.7' # Logging in via Facebook and Twitter, older version.
gem 'oauth2', '0.8.0' # Logging in via Facebook and Twitter
gem 'paperclip', '3.3.1' # Uploading files, such as icons for users and collections.
gem 'rails_autolink', '1.0.9' # Adding links to user-entered text.
gem 'rails3-jquery-autocomplete', '1.0.11', :git => "git://github.com/pleary/rails3-jquery-autocomplete.git" # Autocomplete Ajax.
gem 'recaptcha', '0.3.4', :require => 'recaptcha/rails' # An empathy test to see if you're a human, when creating an account.
gem 'resque', '1.23.0', :require => 'resque/server' # For background jobs, like email notifications and classification curation
gem 'sanitize', '2.0.3' # To clean up user-enter HTML.
gem 'sass-rails', '3.2.5' # To make CSS easier to write.
gem 'sparql-client' # For the data tab
gem 'statsd-ruby', '1.2.1' # For recording various stats around the site.
gem 'uglifier', '1.3.0' # For smaller JS when assets are compiled
gem 'unicorn', '4.4.0' # This is our webserver
gem 'uuid', '2.3.5' # Used when creating data objects
gem 'will_paginate', '3.0.4' # Used ALL OVER THE SITE for pagination.
gem 'nunes', '0.3.0'  # This makes it easier to handle statsd
