$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'indifferent-variable-hash'
require 'eol_scenarios/eol_scenarios'
require 'eol_scenarios/eol_scenario'

# TODO not 100% sure if i want this
EolScenario.load_paths ||= [ 'scenarios' ] # default to a 'scenarios' directory relative to your current location

# TODO get rid of this ... switch to a real logger
EolScenario.verbose = false

# TODO get rid of this, i think i want to *explicitly* require this
require 'eol_scenarios/spec' if defined? Spec

