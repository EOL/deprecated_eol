require File.dirname(__FILE__) + '/../../spec_helper'

def do_index
  get :index, :user_id => @collections[:user].id.to_i
end

describe Users::CollectionsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :collections
    @collections = EOL::TestInfo.load('collections')
  end

  describe 'GET index' do

    it "should instantiate the user through the users controller" do
      do_index
      assigns[:user].should be_a(User)
    end

    it "should instantiate and sort user collections" do
      assigns[:featured_collections].should be_a(Array)
      assigns[:featured_collections].first.should be_a(Collection)
      assigns[:featured_collections].first.id.should == @collections[:collection].id
      assigns[:featured_collections].last.id.should == @collections[:collection_oldest].id

      get :index, :user_id => @collections[:user].id.to_i, :sort_by => "oldest"
      assigns[:featured_collections].first.id.should == @collections[:collection_oldest].id
      assigns[:featured_collections].last.id.should == @collections[:collection].id
    end

    it "should count collection items"

  end

end
