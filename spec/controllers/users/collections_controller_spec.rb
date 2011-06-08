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

  describe 'GET show' do

    it "should instantiate the user through the users controller" do
      do_index
      assigns[:user].should be_a(User)
    end

    it "should instantiate user collections" do
      do_index
      assigns[:collections].should be_a(Array)
      assigns[:collections].first.should be_a(Collection)
    end

    it "should count collection items"

  end

end
