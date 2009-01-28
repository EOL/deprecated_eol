require File.dirname(__FILE__) + '/../spec_helper'

# this isn't exactly a model ... just something that helps 
# with out development and speccing
describe EOL::Scenario do

  def path_to_scenarios
    File.join RAILS_ROOT, 'spec', 'examples', 'scenarios'
  end
  def path_to_more_scenarios
    File.join RAILS_ROOT, 'spec', 'examples', 'more_scenarios'
  end

  before do
    EOL::Scenario.load_paths = [ path_to_scenarios ]
    $set_by_first_scenario = nil
    $set_by_foo = nil
  end

  it 'should find scenario files properly' do
    EOL::Scenario.load_paths = []
    EOL::Scenario.all.should be_empty

    EOL::Scenario.load_paths = [ path_to_scenarios ]
    EOL::Scenario.all.length.should == 1
    EOL::Scenario.all.first.name.should == 'first'

    EOL::Scenario.load_paths << path_to_more_scenarios
    EOL::Scenario.all.length.should == 2
    EOL::Scenario.all.map(&:name).should include('first')
    EOL::Scenario.all.map(&:name).should include('foo')
  end

  it 'should be easy to get a scenario by name' do
    EOL::Scenario[:first].name.should == 'first'
    EOL::Scenario['first'].name.should == 'first'

    EOL::Scenario[:foo].should be_nil
    EOL::Scenario.load_paths << path_to_more_scenarios
    EOL::Scenario[:foo].should_not be_nil
  end

  it 'should be easy to get multiple scenarios by name' do
    EOL::Scenario[:first, :nonexistent, :notfound].length.should == 1
    EOL::Scenario[:first, :nonexistent, :notfound].first.name.should == 'first'

    EOL::Scenario[:first, :nonexistent, :foo].length.should == 1
    EOL::Scenario.load_paths << path_to_more_scenarios
    EOL::Scenario[:first, :nonexistent, :foo].length.should == 2
    EOL::Scenario[:first, :nonexistent, :foo].map(&:name).should include('first')
    EOL::Scenario[:first, :nonexistent, :foo].map(&:name).should include('foo')
  end

  it 'should have a name' do
    EOL::Scenario.all.first.should be_a_kind_of(EOL::Scenario)
    EOL::Scenario.all.first.name.should == 'first'
  end

  it 'should have a description' do
    EOL::Scenario.all.first.description.should == 'i am the description'
  end

  it 'should be loadable' do
    $set_by_first_scenario.should be_nil
    EOL::Scenario[:first].load
    $set_by_first_scenario.should == 'hello from first scenario!'
  end

  it 'should be able to load multiple scenarios' do
    EOL::Scenario.load_paths << path_to_more_scenarios

    $set_by_first_scenario.should be_nil
    $set_by_foo.should be_nil

    EOL::Scenario[:first, :foo].each {|scenario| scenario.load }

    $set_by_first_scenario.should == 'hello from first scenario!'
    $set_by_foo.should == 'hello from foo!'
  end

  it 'should be really easy to load multiple scenarios' do
    EOL::Scenario.load_paths << path_to_more_scenarios

    $set_by_first_scenario.should be_nil
    $set_by_foo.should be_nil

    EOL::Scenario.load :first, :foo

    $set_by_first_scenario.should == 'hello from first scenario!'
    $set_by_foo.should == 'hello from foo!'
  end

  it 'to_s should be the scenario name' do
    EOL::Scenario[:first].to_s.should == 'first'
  end

end
