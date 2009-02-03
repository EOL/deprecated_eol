# This generator creates a new 'scenario'
class ScenarioGenerator < Rails::Generator::Base

  attr_accessor :name_of_scenario_to_create, :name_of_scenario_file_to_create

  # `./script/generate scenario foo` will result in:
  #
  #   runtime_args: ['foo']
  #   runtime_options: {:quiet=>false, :generator=>"scenario", :command=>:create, :collision=>:ask}
  #
  def initialize(runtime_args, runtime_options = {})
    # setup_rails_to_run_scenarios
    @name_of_scenario_to_create      = runtime_args.join(' ')
    @name_of_scenario_file_to_create = runtime_args.join('_').downcase
    super
  end

  # this should be done by ./script/generate blackbox
  def setup_rails_to_run_scenarios
    # bootstrap
  end

  def manifest
    record do |m|
      m.directory 'scenarios'
      m.template 'scenario.erb', "scenarios/#{ name_of_scenario_file_to_create }.rb"
    end
  end
 
protected
 
  def banner
    "Usage: #{$0} _scenario Name of Scenario to Create"
  end
 
end
