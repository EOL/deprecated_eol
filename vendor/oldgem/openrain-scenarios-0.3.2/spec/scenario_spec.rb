require File.dirname(__FILE__) + '/spec_helper'

describe Scenario do

  def path_to_test_scenarios
    File.join File.dirname(__FILE__), '..', 'examples', 'scenarios'
  end
  def path_to_more_scenarios
    File.join File.dirname(__FILE__), '..', 'examples', 'more_scenarios'
  end

  before do
    Scenario.load_paths = [ path_to_test_scenarios ]
    $set_by_first_scenario = nil
    $set_by_foo = nil
  end

  before :all do
    @original_scenario_paths = Scenario.load_paths
  end
  after :all do
    Scenario.load_paths = @original_scenario_paths
  end

  # PENDING
  # it 'should grab variables from header (yaml?)'
  # it 'should not *require* a summary'
  # it 'should not *require* a description'

  it 'should find scenario files properly' do
    Scenario.load_paths = []
    Scenario.all.should be_empty

    Scenario.load_paths = [ path_to_test_scenarios ]
    Scenario.all.length.should == 1
    Scenario.all.first.name.should == 'first'

    Scenario.load_paths << path_to_more_scenarios
    Scenario.all.length.should == 2
    Scenario.all.map(&:name).should include('first')
    Scenario.all.map(&:name).should include('foo')
  end

  it 'should be easy to get a scenario by name' do
    Scenario[:first].name.should == 'first'
    Scenario['first'].name.should == 'first'

    Scenario[:foo].should be_nil
    Scenario.load_paths << path_to_more_scenarios
    Scenario[:foo].should_not be_nil
  end

  it 'should be easy to get multiple scenarios by name' do
    Scenario[:first, :nonexistent, :notfound].length.should == 1
    Scenario[:first, :nonexistent, :notfound].first.name.should == 'first'

    Scenario[:first, :nonexistent, :foo].length.should == 1
    Scenario.load_paths << path_to_more_scenarios
    Scenario[:first, :nonexistent, :foo].length.should == 2
    Scenario[:first, :nonexistent, :foo].map(&:name).should include('first')
    Scenario[:first, :nonexistent, :foo].map(&:name).should include('foo')
  end

  it 'should have a name' do
    Scenario.all.first.should be_a_kind_of(Scenario)
    Scenario.all.first.name.should == 'first'
  end

  it 'should have a summary' do
    Scenario.all.first.summary.should == 'i am the summary'
  end

  it 'should have a description' do
    Scenario.all.first.description.should == "i am the summary\n\n  only the first line\n  should be included in the summary\n\nno space here"
  end

  it 'should allow yaml in the header to load up some custom variables (needs to be a hash)' do
    path = File.join File.dirname(__FILE__), '..', 'examples', 'yaml_frontmatter'
    Scenario.load_paths << path

    Scenario[:yaml_in_header].name.should == 'yaml_in_header'
    Scenario[:yaml_in_header].summary.should == 'i have some yaml'
    Scenario[:yaml_in_header].description.should == "i have some yaml\n\n  hi there\n  indeed i do"
    Scenario[:yaml_in_header].header.should include('foo: x')
    Scenario[:yaml_in_header].foo.should == 'x'
  end

  it 'should be loadable' do
    $set_by_first_scenario.should be_nil
    Scenario[:first].load
    $set_by_first_scenario.should == 'hello from first scenario!'
  end

  it 'should be able to load multiple scenarios and run any dependencies' do
    $times_loads_stuff_has_been_run, $times_loads_more_stuff_has_been_run = nil, nil
    path = File.join File.dirname(__FILE__), '..', 'examples', 'testing_dependencies'
    Scenario.load_paths << path

    Scenario[:load_more_stuff].dependencies.should include(:load_stuff)

    $times_loads_stuff_has_been_run.should be_nil
    $times_loads_more_stuff_has_been_run.should be_nil

    Scenario.load :load_stuff, :unique => false
    $times_loads_stuff_has_been_run.should == 1
    $times_loads_more_stuff_has_been_run.should be_nil

    Scenario.load :load_stuff, :load_stuff, :unique => false
    $times_loads_stuff_has_been_run.should == 3
    $times_loads_more_stuff_has_been_run.should be_nil

    Scenario.load :load_more_stuff, :unique => false
    $times_loads_stuff_has_been_run.should == 4 # should be run once, as it's a dependency
    $times_loads_more_stuff_has_been_run.should == 1

    Scenario.load :load_stuff, :load_more_stuff, :unique => false
    $times_loads_stuff_has_been_run.should == 6 # should be run twice
    $times_loads_more_stuff_has_been_run.should == 2
  end

  it 'should be able to load multiple scenarios and run any dependencies (running each dependency only once!)' do
    $times_loads_stuff_has_been_run, $times_loads_more_stuff_has_been_run = nil, nil
    path = File.join File.dirname(__FILE__), '..', 'examples', 'testing_dependencies'
    Scenario.load_paths << path

    Scenario.load :load_stuff, :load_more_stuff #, :unique => true  # <--- this should be the default!
    $times_loads_stuff_has_been_run.should == 1 # should only run once!
    $times_loads_more_stuff_has_been_run.should == 1
  end

  it 'should be able to load multiple scenarios' do
    Scenario.load_paths << path_to_more_scenarios

    $set_by_first_scenario.should be_nil
    $set_by_foo.should be_nil

    Scenario[:first, :foo].each {|scenario| scenario.load }

    $set_by_first_scenario.should == 'hello from first scenario!'
    $set_by_foo.should == 'hello from foo!'
  end

  it 'should be really easy to load multiple scenarios' do
    Scenario.load_paths << path_to_more_scenarios

    $set_by_first_scenario.should be_nil
    $set_by_foo.should be_nil

    Scenario.load :first, :foo

    $set_by_first_scenario.should == 'hello from first scenario!'
    $set_by_foo.should == 'hello from foo!'
  end

  it 'to_s should be the scenario name' do
    Scenario[:first].to_s.should == 'first'
  end

  it 'should allow globbing in load_paths' do
    Scenario.load_paths = [ File.join(File.dirname(__FILE__), '..', 'examp*', '**') ]

    Scenario.all.length.should == Dir[File.join(File.dirname(__FILE__), '..', 'examp*', '**', '*.rb')].length
    Scenario.all.map(&:name).should include('first')
    Scenario.all.map(&:name).should include('foo')
  end

end
