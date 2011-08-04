require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionsController do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('collections_scenario')
      truncate_all_tables
      load_scenario_with_caching(:collections)
    end
    @test_data = EOL::TestInfo.load('collections')
    @collection = @test_data[:collection]
    builder = EOL::Solr::CollectionItemsCoreRebuilder.new()
    builder.begin_rebuild
  end

  describe "#update" do
    it "Unauthorized users cannot the description" do
      post :update, :id => @collection.id, :commit_edit_collection => 'Submit',  :collection => {:description => "New Description"}
      @collection.reload
      # getter.should change(@collection, :description)
      response.should be_redirect
      session[:flash][:error].should =~ /not authorized/
      response.redirected_to.should == root_url
      
    end
    it "Updates the description" do
      session[:user] = @collection.user
      getter = lambda{
        post :update, :id => @collection.id, :commit_edit_collection => 'Submit',  :collection => {:description => "New Description"}
        @collection.reload
      }
      getter.should change(@collection, :description)
    end
    
  end

end
