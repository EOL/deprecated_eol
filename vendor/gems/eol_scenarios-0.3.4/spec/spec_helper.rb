$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'eol_scenarios'
require 'spec'
require 'spec/autorun'

include EolScenario::Spec

Spec::Runner.configure do |config|
  
end
