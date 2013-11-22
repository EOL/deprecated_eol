require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionItemsController do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('collections_scenario')
      truncate_all_tables
      load_scenario_with_caching(:collections)
    end
    @test_data = EOL::TestInfo.load('collections')
    @collection_item = @test_data[:collection].collection_items.last
    @collection_editor = @test_data[:collection].users.first
  end

  # This method is used when JS is disabled, otherwise items are updated through Collection controller
  describe "POST update" do
    it "should NOT update the item if user not logged in" do
      post :update, :id => @collection_item.id, :collection_item => {:annotation => "New Annotation"}
      expect(response).to redirect_to(login_url)
    end
    it "should update the item if user has permission to update" do
      getter = lambda{
        session[:user_id] = @collection_editor.id
        post :update, { :id => @collection_item.id, :collection_item => {:annotation => "New Annotation"} }
        @collection_item.reload
        debugger unless @collection_item.annotation == "New Annotation" # What happened?  Seems rare... must be another error.
      }
      getter.should change(@collection_item, :annotation)
    end
  end

end
