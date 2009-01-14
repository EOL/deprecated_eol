require File.dirname(__FILE__) + '/../spec_helper'

ActsAsEnum; # touch to include this ... we should require in environment.rb?

=begin

  NOTES:
    @foo_data_type = DataType.create_valid! :label => 'foo'
    @foo_data_type.attribution_order = [] # DataType.attibution_order[:foo] = [ ... ]
    @foo_data_type.attribution_order = [ :photographer, :author, :source ] # view order should be used for the rest of them ... ?
    @data_object = 

    DataType[:food].attribution_order.should == AgentRole[:foo, :bar]

    Usage, in a view?

    @object

    @object.attribution

    AgentsDataObject
      agent
      data_object
      agent_role
      view_order

=end

describe DataObject, 'attribution' do

  before do
    # kill fixture data that we don't want messing with our specs
    [ DataType, AgentRole, DataObject, AgentsDataObject, Agent ].each &:delete_all
  end

  def create_agent name
    Agent.create_valid! :email => "#{name}@someplace.com", :username => name, :full_name => name
  end
  def get_agent name
    Agent.find_by_username name
  end

  it '... ummm ... should work as I want it to!  :P' do
    @food = DataType.create_valid! :label => 'Food'
    DataType[:Food].should == @food

    %w( Chef IdeaMaker Ninja Robot ).each {|l| AgentRole.create_valid! :label => l }

    DataType[:Food].attribution_order.should be_empty
    DataType[:Food].attribution_order << AgentRole[:Ninja]
    DataType[:Food].attribution_order.should include(AgentRole[:Ninja])
    DataType[:Food].attribution_order << AgentRole[:Robot]
    DataType[:Food].attribution_order.should == AgentRole[ :Ninja, :Robot ]

    DataType[:Food].full_attribution_order.should == AgentRole[ :Ninja, :Robot, :Chef, :IdeaMaker ] # return explicit order + all other agent roles

    # i need int <--> AgentRole or something ... for a particular agent role for a particular data type
    DataType[:Food].attribution_order_for(AgentRole[:Ninja]).should == 0
    DataType[:Food].attribution_order_for(AgentRole[:Robot]).should == 1
    DataType[:Food].attribution_order_for(AgentRole[:Chef]).should == 2
    DataType[:Food].attribution_order_for(AgentRole[:IdeaMaker]).should == 3
  end

  it 'quick create_agent test ...' do
    lambda {
      %w( hello there somebody ).each {|name| create_agent name }
    }.should change(Agent, :count).by(3)
  end
   
  it 'should have different priorities for different agent roles, per data type, also taking view_order into account' do
    %w( Chef IdeaMaker Ninja Robot ).each {|l| AgentRole.create_valid! :label => l }

    @object = DataObject.create_valid!

    marc   = @object.agents_data_objects.create :agent => create_agent('Marc'),  :agent_role => AgentRole[:Chef],  :view_order => 10 # Marc is a chef (should be the last chef)
    robot  = @object.agents_data_objects.create :agent => create_agent('Robot'), :agent_role => AgentRole[:Robot], :view_order => 1
    john   = @object.agents_data_objects.create :agent => create_agent('John'),  :agent_role => AgentRole[:Chef],  :view_order => 3  # John is a chef (should be the first)
    ninja  = @object.agents_data_objects.create :agent => create_agent('Ninja'), :agent_role => AgentRole[:Ninja], :view_order => 99
    remi   = @object.agents_data_objects.create :agent => create_agent('remi'),  :agent_role => AgentRole[:Chef],  :view_order => 7  # remi is a chef (should be the second)

    # without explicit priorities ( should order by ... database ID of each AgentRole?  no better way ... maybe by name? )
    @object.attributions.should == [ john, remi, marc, ninja, robot ] # <--- sorts by vieworder, but agentroles are sorted by database ID

    # with explicit priorities
    # MAKE PRIORITIES ... 
    # @object.attributions.should == [ john, remi, marc, ninja, robot ] # <--- sorts by vieworder, with agentroles sorted by priority
  end
  
end
