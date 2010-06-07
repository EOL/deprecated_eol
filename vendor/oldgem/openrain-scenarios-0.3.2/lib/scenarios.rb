$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'indifferent-variable-hash'
require 'scenarios/scenarios'
require 'scenarios/scenario'

# TODO not 100% sure if i want this
Scenario.load_paths ||= [ 'scenarios' ] # default to a 'scenarios' directory relative to your current location

# TODO get rid of this ... switch to a real logger
Scenario.verbose = false

# TODO get rid of this, i think i want to *explicitly* require this
require 'scenarios/spec' if defined? Spec
