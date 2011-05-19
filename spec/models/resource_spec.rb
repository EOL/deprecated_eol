require File.dirname(__FILE__) + '/../spec_helper'

describe Agent do

  before(:all) do
    load_foundation_cache
    iucn_user = User.find_by_display_name('IUCN')
    iucn_content_partner = ContentPartner.find_by_user_id(iucn_user.id)

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
