source 'http://rubygems.org'

group :development, :test, :staging_dev do
  gem 'capistrano', '2.13.5'
  gem 'capistrano-unicorn-pleary', '=0.1.6.1'
  gem 'rvm-capistrano', '1.2.7'
  gem 'capybara', '1.1.3'
  gem 'daemons', '1.1.9'
  gem 'debugger', '1.2.1'
  gem 'factory_girl_rails', '4.1.0'
  gem 'faker', '1.1.2'
  gem 'haml-rails' # Just for rails generators.
  gem 'optiflag', '0.7'
  gem 'rspec-rails', '2.11.4'
  gem 'ruby-prof', '0.11.2'
  gem 'spin', '0.5.3'
  # These are only for the RDF-store tests:
  gem 'rest-client', '1.6.7'
  gem 'sparql-client'
  gem 'rdoc', '3.12'
  gem 'nokogiri', '1.5.5' # Yeah, I know this has given us grief in the past.  :\ Trying things out, is all.
end

group :staging do
  gem 'debugger', '1.2.1'
end

group :development, :staging_dev, :staging_dev_cache do
  gem 'webrick', '1.3.1'
end

group :production do
  gem 'therubyracer', '0.10.2'
  gem 'execjs', '1.4.0'
end

group :test do
  gem 'webmock', '1.8.11'
  gem 'rspec-html-matchers', '0.3.5'
end

group :assets do
  gem 'turbo-sprockets-rails3', '0.3.4'
end

gem 'rails', '3.2.12'

gem 'acts_as_tree_rails3', '0.1.0'
gem 'biodiversity19'
gem 'ckeditor', '3.7.3'
gem 'coffee-rails', '3.2.2'
gem 'composite_primary_keys'
gem 'dalli', '2.3.0'
gem 'ar-octopus', '0.4.0', :git => "git://github.com/pleary/octopus.git", :branch => "0.4.0", :require => "octopus"
gem 'email_spec', '1.4.0'
gem 'escape', '0.0.4'
gem 'ezcrypto', '0.7.2'
gem 'graylog2_exceptions', '1.3.0'
gem 'haml', '3.1.7'
gem 'indifferent-variable-hash', '0.1.0'
gem 'invert', '0.1.0'
gem 'jquery-rails', '2.1.3'
gem 'json', '1.7.7'
gem 'macaddr', '1.6.1'
gem 'mime-types', '1.19'
gem 'mysql2', '0.3.11'
gem 'newrelic_rpm', '>3.5.3'
gem 'oauth', '0.4.7'
gem 'oauth2', '0.8.0'
gem 'paperclip', '3.3.1'
gem 'rails_autolink', '1.0.9'
gem 'recaptcha', '0.3.4', :require => 'recaptcha/rails'
gem 'resque', '1.23.0', :require => 'resque/server'
gem 'sanitize', '2.0.3'
gem 'sass-rails', '3.2.5'
gem 'uglifier', '1.3.0'
gem 'unicorn', '4.4.0'
gem 'uuid', '2.3.5'
gem 'will_paginate', '3.0.3'
