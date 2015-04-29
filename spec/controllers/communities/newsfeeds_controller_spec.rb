require File.dirname(__FILE__) + '/../../spec_helper'

def newsfeeds_do_show
  get :show, community_id: @community.id
end

describe Communities::NewsfeedsController do

  before(:all) do
    @community = Community.gen
  end

  describe 'GET show' do

    it "should instantiate the community" do
      newsfeeds_do_show
      assigns[:community].should be_a(Community)
      assigns[:community].id.should == @community.id
    end

  end

end
