# this should get you up and running for using RackBox with RSpec
require File.dirname(__FILE__) + '/../rackbox'

spec_configuration = nil
spec_configuration = Spec::Example if defined? Spec::Example
spec_configuration = Spec::Runner if defined? Spec::Runner

spec_configuration.configure do |config|
  config.use_blackbox = true
end
