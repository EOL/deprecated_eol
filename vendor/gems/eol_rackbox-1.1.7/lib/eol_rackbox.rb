$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'rack'
require 'rails-rack-adapter' # update this so it's only loaded when/if needed

require 'rackbox/rack/content_length_fix'
require 'rackbox/rack/sticky_sessions'
require 'rackbox/rack/extensions_for_rspec'

require 'rackbox/rackbox'
require 'rackbox/app'

require 'rspec/custom_matcher'
require 'rackbox/matchers'

require 'rackbox/spec/helpers'
require 'rackbox/spec/configuration'
