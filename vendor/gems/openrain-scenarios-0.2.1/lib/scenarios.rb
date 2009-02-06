$:.unshift File.dirname(__FILE__)

require 'scenarios/scenario'

Scenario.load_paths ||= [ 'scenarios' ] # default to a 'scenarios' directory relative to your current location
Scenario.verbose = false

require 'scenarios/spec' if defined? Spec
