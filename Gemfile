source 'http://rubygems.org'

group :development, :test do
  gem 'capistrano'
  gem 'capistrano-unicorn-pleary'
  gem 'rvm-capistrano'
  gem 'capybara'
  gem 'daemons'
  gem 'debugger'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'optiflag'
  gem 'rspec-rails', '~>2.0'
  gem 'ruby-prof'
end

group :staging do
  gem 'debugger'
end

group :development, :staging_dev, :staging_dev_cache do
  gem 'webrick'
end

group :production do
  gem 'therubyracer'
  gem 'execjs'
end

group :test do
  gem 'webmock'
  gem 'rspec-html-matchers'
end

group :assets do
  gem 'turbo-sprockets-rails3'
end

group :worker do
  # TODO - try adding this again later; it doesn't appear to work with Ruby 1.9 ...we might not need it there,
  # though.
  #gem 'system_timer'
end

gem 'rails', '3.2.7'

gem 'acts_as_tree_rails3'
gem 'ckeditor'
gem 'coffee-rails'
gem 'composite_primary_keys'
gem 'dalli'
gem 'ar-octopus', :git => "git://github.com/tchandy/octopus.git", :require => "octopus"
gem 'email_spec'
gem 'escape'
gem 'ezcrypto'
gem 'graylog2_exceptions'
gem 'haml'
gem 'haml-i18n'
gem 'indifferent-variable-hash'
gem 'invert'
gem 'jquery-rails'
gem 'json'
gem 'macaddr'
gem 'mime-types'
gem 'mysql2'
gem 'newrelic_rpm'
gem 'oauth'
gem 'oauth2'
gem 'paperclip'
gem 'rails_autolink'
gem 'recaptcha', :require => 'recaptcha/rails'
gem 'resque', :require => 'resque/server'
gem 'rdoc'
gem 'sanitize'
gem 'sass-rails'
gem 'uglifier'
gem 'unicorn'
gem 'uuid'
gem 'will_paginate'
