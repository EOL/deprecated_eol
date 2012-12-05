class EolScenario

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
    #   require 'eol_scenarios'
    #
    #   Spec::Runner.configure do |config|
    #     include EolScenario::Spec
    #   end
    #
    # is RSpec is loaded, we'll load up the EolScenario::Spec for 
    # you automatically.  if you need to manually load this:
    #
    #   require 'eol_scenarios/spec'
    #
    def scenario *scenarios
      puts "EolScenario::Spec::Helper.scenario #{ scenarios.inspect }" if EolScenario.verbose
      options = (scenarios.last.is_a?Hash) ? scenarios.pop : { }
      options[:before] ||= :each
      before options[:before] do
        EolScenario.load *scenarios
      end
    end
    alias scenarios scenario

  end

end
