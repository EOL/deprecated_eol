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
    it "Unauthorized users cannot update the description" do
      expect{ post :update, :id => @collection.id, :commit_edit_collection => 'Submit',
                            :collection => {:description => "New Description"} }.should raise_error(EOL::Exceptions::MustBeLoggedIn)
      user = User.gen
      expect{ post :update, { :id => @collection.id, :commit_edit_collection => 'Submit', :collection => {:description => "New Description"} },
                            { :user => user, :user_id => user.id } }.should raise_error(EOL::Exceptions::SecurityViolation)

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
