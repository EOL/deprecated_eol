require File.dirname(__FILE__) + '/../lib/scenarios'

Spec::Runner.configure do |config|
  include Scenario::Spec
end
