require File.dirname(__FILE__) + '/../../spec_helper'

def do_index
  get :index, :user_id => @collections[:user].id.to_i
  response.should be_success # No sense in continuing otherwise.
end

describe Users::CollectionsController do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    collections = {}
    collections[:user] = User.gen
    collections[:user2] = User.gen
    collections[:community] = Community.gen
    collections[:collection] = Collection.gen
    collections[:collection].users = [collections[:user]]
    collections[:collection_oldest] = Collection.gen(:created_at => collections[:collection].created_at - 86400)
    collections[:collection_oldest].users = [collections[:user]]
    @collections = collections
  end

  describe 'GET index' do

    before(:each) { do_index }

    it "should instantiate the user through the users controller" do
      assigns[:user].should be_a(User)
    end

    it "should instantiate and sort user collections" do
      assigns[:published_collections].should be_a(Array)
      assigns[:published_collections].first.should be_a(Collection)
      assigns[:published_collections].should == assigns[:published_collections].sort_by(&:name)

      get :index, :user_id => @collections[:user].id.to_i, :sort_by => "oldest"
      assigns[:published_collections].should == assigns[:published_collections].sort_by(&:created_at)
    end

    it "should count collection items"

  end

end
