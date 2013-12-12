require 'spec_helper'

def clear_curator_community_cache
  Rails.cache.delete('test/communities/name/EOL_Curators')
end

describe CuratorCommunity do

  before(:all) do
    load_foundation_cache # Needs data_type info.
  end

  it 'should be able to get the community' do
    CuratorCommunity.get.should_not be_nil
  end

  it 'should be able to build the community' do
    CuratorCommunity.get.try(:destroy)
    clear_curator_community_cache
    curator = User.gen(curator_level_id: 1, credentials: 'fun', curator_scope: 'joy')
    community = CuratorCommunity.build
    community.should_not be_nil
    community.name.should == $CURATOR_COMMUNITY_NAME
    community.description.should == $CURATOR_COMMUNITY_DESC
    curator.is_member_of?(community).should be_true
    community.members.each do |member|
      member.user.is_curator?.should be_true
    end
  end

  it 'should not be able to change its name' do
    comm = CuratorCommunity.get
    comm.name = 'Something new'
    comm.save
    clear_curator_community_cache
    CuratorCommunity.get.name.should == $CURATOR_COMMUNITY_NAME
  end

end
