require File.dirname(__FILE__) + '/../../spec_helper'

def newsfeeds_do_show
  get :show, :community_id => @communities[:community].id.to_i
end

describe Communities::NewsfeedsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :communities
    @communities = EOL::TestInfo.load('communities')
  end

  describe 'GET show' do

    it "should instantiate the community" do
      newsfeeds_do_show
      assigns[:community].should be_a(Community)
      assigns[:community].id.should == @communities[:community].id
    end

  end

end
