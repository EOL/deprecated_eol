class Scenario

  # scenario helpers that can be used in your specs
  #
  # specifically, a #scenarios method for easily loading scenarios
  #
  module Spec

    # scenarios to load in a spec
    #
    #   scenario  :foo
    #   scenarios :foo, :bar
    #   scenarios :foo, :bar, :before => :all
    #   scenarios :foo, :bar, :before => :each
    #
    # defaults to before each
    #
    # to use this in your own specs, in your spec_helper.rb
    #
    #   require 'scenarios'
    #
    #   Spec::Runner.configure do |config|
    #     include Scenario::Spec
    #   end
    #
    # is RSpec is loaded, we'll load up the Scenario::Spec for 
    # you automatically.  if you need to manually load this:
    #
    #   require 'scenarios/spec'
    #
    def scenario *scenarios
      puts "Scenario::Spec::Helper.scenario #{ scenarios.inspect }" if Scenario.verbose
      options = (scenarios.last.is_a?Hash) ? scenarios.pop : { }
      options[:before] ||= :each
      before options[:before] do
        Scenario.load *scenarios
      end
    end
    alias scenarios scenario

  end

end
