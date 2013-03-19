require File.dirname(__FILE__) + '/../../spec_helper'

def do_index
  get :index, :user_id => @collections[:user].id.to_i
  response.should be_success # No sense in continuing otherwise.
end

describe Users::CollectionsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :collections
    @collections = EOL::TestInfo.load('collections')
  end

  describe 'GET index' do

    before(:each) { do_index }

    it "should instantiate the user through the users controller" do
      assigns[:user].should be_a(User)
    end

    it "should instantiate and sort user collections" do
      assigns[:published_collections].should be_a(Array)
      assigns[:published_collections].first.should be_a(Collection)
      assigns[:published_collections].should == assigns[:published_collections].sort_by { |c| - c.created_at.to_i }

      get :index, :user_id => @collections[:user].id.to_i, :sort_by => "oldest"
      assigns[:published_collections].should == assigns[:published_collections].sort_by(&:created_at)
    end

    it "should count collection items"

  end

end
