require File.dirname(__FILE__) + '/spec_helper'

describe Scenario::Spec do

  def path_to_test_scenarios
    File.join File.dirname(__FILE__), '..', 'examples', 'scenarios'
  end
  def path_to_additional_scenarios
    File.join File.dirname(__FILE__), '..', 'examples', 'additional_scenarios'
  end

  before :all do
    $set_by_load_me.should be_nil
    $set_by_load_me_too.should be_nil
    @original_scenario_paths = Scenario.load_paths
  end
  after :all do
    Scenario.load_paths = @original_scenario_paths
  end

  scenarios :load_me, :load_me_too # <---- this is what we're testing here
                                   #       see spec_helper.rb for how to 
                                   #       add this method to your app!

  it 'should have the scenarios we want to try running' do
    Scenario.load_paths = [ path_to_additional_scenarios ]
    Scenario.all.length.should == 2
    Scenario.all.map(&:name).should include('load_me')
    Scenario.all.map(&:name).should include('load_me_too')
  end

  it 'should actually load the scenarios ok' do
    $set_by_load_me.should == 'I was set by load_me'
    $set_by_load_me_too.should == 'I was set by load_me_too!'
  end

end
