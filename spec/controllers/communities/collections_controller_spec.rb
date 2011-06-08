require File.dirname(__FILE__) + '/../../spec_helper'

def do_index
  get :index, :community_id => @collections[:community].id.to_i
end

describe Communities::CollectionsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :collections
    @collections = EOL::TestInfo.load('collections')
  end

  describe 'GET show' do

    it "should instantiate the community" do
      do_show
      assigns[:community].should be_a(Community)
    end

    it "should load a community's focus collection"
    it "should load a community's endorsed collections"
  end

end
