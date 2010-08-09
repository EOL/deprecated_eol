require File.dirname(__FILE__) + '/spec_helper'

describe EolScenario do

  def path_to_test_scenarios
    File.join File.dirname(__FILE__), '..', 'examples', 'scenarios'
  end
  def path_to_more_scenarios
    File.join File.dirname(__FILE__), '..', 'examples', 'more_scenarios'
  end

  before do
    EolScenario.load_paths = [ path_to_test_scenarios ]
    $set_by_first_scenario = nil
    $set_by_foo = nil
  end

  before :all do
    @original_scenario_paths = EolScenario.load_paths
  end
  after :all do
    EolScenario.load_paths = @original_scenario_paths
  end

  # PENDING
  # it 'should grab variables from header (yaml?)'
  # it 'should not *require* a summary'
  # it 'should not *require* a description'

  it 'should find scenario files properly' do
    EolScenario.load_paths = []
    EolScenario.all.should be_empty

    EolScenario.load_paths = [ path_to_test_scenarios ]
    EolScenario.all.length.should == 1
    EolScenario.all.first.name.should == 'first'

    EolScenario.load_paths << path_to_more_scenarios
    EolScenario.all.length.should == 2
    EolScenario.all.map(&:name).should include('first')
    EolScenario.all.map(&:name).should include('foo')
  end

  it 'should be easy to get a scenario by name' do
    EolScenario[:first].name.should == 'first'
    EolScenario['first'].name.should == 'first'

    EolScenario[:foo].should be_nil
    EolScenario.load_paths << path_to_more_scenarios
    EolScenario[:foo].should_not be_nil
  end

  it 'should be easy to get multiple scenarios by name' do
    EolScenario[:first, :nonexistent, :notfound].length.should == 1
    EolScenario[:first, :nonexistent, :notfound].first.name.should == 'first'

    EolScenario[:first, :nonexistent, :foo].length.should == 1
    EolScenario.load_paths << path_to_more_scenarios
    EolScenario[:first, :nonexistent, :foo].length.should == 2
    EolScenario[:first, :nonexistent, :foo].map(&:name).should include('first')
    EolScenario[:first, :nonexistent, :foo].map(&:name).should include('foo')
  end

  it 'should have a name' do
    EolScenario.all.first.should be_a_kind_of(EolScenario)
    EolScenario.all.first.name.should == 'first'
  end

  it 'should have a summary' do
    EolScenario.all.first.summary.should == 'i am the summary'
  end

  it 'should have a description' do
    EolScenario.all.first.description.should == "i am the summary\n\n  only the first line\n  should be included in the summary\n\nno space here"
  end

  it 'should allow yaml in the header to load up some custom variables (needs to be a hash)' do
    path = File.join File.dirname(__FILE__), '..', 'examples', 'yaml_frontmatter'
    EolScenario.load_paths << path

    EolScenario[:yaml_in_header].name.should == 'yaml_in_header'
    EolScenario[:yaml_in_header].summary.should == 'i have some yaml'
    EolScenario[:yaml_in_header].description.should == "i have some yaml\n\n  hi there\n  indeed i do"
    EolScenario[:yaml_in_header].header.should include('foo: x')
    EolScenario[:yaml_in_header].foo.should == 'x'
  end

  it 'should be loadable' do
    $set_by_first_scenario.should be_nil
    EolScenario[:first].load
    $set_by_first_scenario.should == 'hello from first scenario!'
  end

  it 'should be able to load multiple scenarios and run any dependencies' do
    $times_loads_stuff_has_been_run, $times_loads_more_stuff_has_been_run = nil, nil
    path = File.join File.dirname(__FILE__), '..', 'examples', 'testing_dependencies'
    EolScenario.load_paths << path

    EolScenario[:load_more_stuff].dependencies.should include(:load_stuff)

    $times_loads_stuff_has_been_run.should be_nil
    $times_loads_more_stuff_has_been_run.should be_nil

    EolScenario.load :load_stuff, :unique => false
    $times_loads_stuff_has_been_run.should == 1
    $times_loads_more_stuff_has_been_run.should be_nil

    EolScenario.load :load_stuff, :load_stuff, :unique => false
    $times_loads_stuff_has_been_run.should == 3
    $times_loads_more_stuff_has_been_run.should be_nil

    EolScenario.load :load_more_stuff, :unique => false
    $times_loads_stuff_has_been_run.should == 4 # should be run once, as it's a dependency
    $times_loads_more_stuff_has_been_run.should == 1

    EolScenario.load :load_stuff, :load_more_stuff, :unique => false
    $times_loads_stuff_has_been_run.should == 6 # should be run twice
    $times_loads_more_stuff_has_been_run.should == 2
  end

  it 'should be able to load multiple scenarios and run any dependencies (running each dependency only once!)' do
    $times_loads_stuff_has_been_run, $times_loads_more_stuff_has_been_run = nil, nil
    path = File.join File.dirname(__FILE__), '..', 'examples', 'testing_dependencies'
    EolScenario.load_paths << path

    EolScenario.load :load_stuff, :load_more_stuff #, :unique => true  # <--- this should be the default!
    $times_loads_stuff_has_been_run.should == 1 # should only run once!
    $times_loads_more_stuff_has_been_run.should == 1
  end

  it 'should be able to load multiple scenarios' do
    EolScenario.load_paths << path_to_more_scenarios

    $set_by_first_scenario.should be_nil
    $set_by_foo.should be_nil

    EolScenario[:first, :foo].each {|scenario| scenario.load }

    $set_by_first_scenario.should == 'hello from first scenario!'
    $set_by_foo.should == 'hello from foo!'
  end

  it 'should be really easy to load multiple scenarios' do
    EolScenario.load_paths << path_to_more_scenarios

    $set_by_first_scenario.should be_nil
    $set_by_foo.should be_nil

    EolScenario.load :first, :foo

    $set_by_first_scenario.should == 'hello from first scenario!'
    $set_by_foo.should == 'hello from foo!'
  end

  it 'to_s should be the scenario name' do
    EolScenario[:first].to_s.should == 'first'
  end

  it 'should allow globbing in load_paths' do
    EolScenario.load_paths = [ File.join(File.dirname(__FILE__), '..', 'examp*', '**') ]

    EolScenario.all.length.should == Dir[File.join(File.dirname(__FILE__), '..', 'examp*', '**', '*.rb')].length
    EolScenario.all.map(&:name).should include('first')
    EolScenario.all.map(&:name).should include('foo')
  end

end
