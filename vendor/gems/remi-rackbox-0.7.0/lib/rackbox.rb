# TODO split up into different files!  sheesh!

$:.unshift File.dirname(__FILE__)
require 'rubygems'
begin
  require 'thin' # required for Rails pre Rails 2.3, as Thin has the Rack::Adapter::Rails
rescue LoadError
end

require 'rack'

require 'rackbox/rack/content_length_fix'
require 'rackbox/rack/sticky_sessions'
require 'rackbox/rack/extensions_for_rspec'

require 'rackbox/rackbox'

require 'rspec/custom_matcher'
require 'rackbox/matchers'

require 'rackbox/spec/helpers'
require 'rackbox/spec/configuration'
