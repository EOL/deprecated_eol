require File.dirname(__FILE__) + '/../../spec_helper'

def do_show
  get :show, :community_id => @communities[:community].id.to_i
end

describe Communities::NewsfeedsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :communities
    @communities = EOL::TestInfo.load('communities')
  end

  describe 'GET show' do

    it "should load the community instance through the communities controller" do
      do_show
      assigns[:community].should be_a(Community)
    end
    it "should instantiate a feed item for the community and current user" do
      do_show
      assigns[:feed_item].should be_a(FeedItem)
    end

  end

end
