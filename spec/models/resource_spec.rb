require File.dirname(__FILE__) + '/../spec_helper'

describe Agent do

  before(:all) do
    truncate_all_tables
    iucn_agent = Agent.iucn || Agent.gen(:full_name => 'IUCN')
    iucn_user = User.gen(:agent => iucn_agent)
    iucn_content_partner = ContentPartner.gen(:user => iucn_user)
    
    @iucn_resource1 = Resource.gen(:content_partner => iucn_content_partner)
    @iucn_resource2 = Resource.gen(:content_partner => iucn_content_partner)
  end

  # TODO - test this model!  Sheesh.

  describe "iucn" do
    it 'returns the last IUCN resource' do
      Resource.iucn.should == @iucn_resource2
    end
  end

end
