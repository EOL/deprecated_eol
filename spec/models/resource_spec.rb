require File.dirname(__FILE__) + '/../spec_helper'

describe Agent do

  before(:all) do
    truncate_all_tables
    @iucn_agent     = Agent.iucn
    @iucn_agent   ||= Agent.gen(:full_name => 'IUCN')
    @iucn_resource1 = Resource.gen()
    @iucn_resource2 = Resource.gen()
    AgentsResource.gen(:agent => @iucn_agent, :resource => @iucn_resource1)
    AgentsResource.gen(:agent => @iucn_agent, :resource => @iucn_resource2)
  end

  # TODO - test this model!  Sheesh.

  describe "iucn" do
    it 'returns the last IUCN resource' do
      Resource.iucn.should == @iucn_resource2
    end
  end

end
