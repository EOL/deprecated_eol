require File.dirname(__FILE__) + '/../spec_helper'

describe Agent do

  before(:all) do
    @iucn_agent     = Agent.iucn
    @iucn_agent   ||= Agent.gen(:full_name => 'IUCN')
    @iucn_resource1 = Resource.gen()
    @iucn_resource2 = Resource.gen()
    AgentsResource.gen(:agent => @iucn_agent, :resource => @iucn_resource1)
    AgentsResource.gen(:agent => @iucn_agent, :resource => @iucn_resource2)
  end

  describe "iucn" do
    it 'returns an array of IUCN resources' do
      Resource.iucn.sort_by {|r| r.id }.should == [@iucn_resource1, @iucn_resource2]
    end
  end

end
