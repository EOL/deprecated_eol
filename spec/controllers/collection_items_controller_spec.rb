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

  # This method is used both when JS is disabled and enabled rendering different views for HTML and JS formats
  describe "GET edit" do
    it "should render edit if user has permission to update" do
      get :edit, :id => @collection_item.id
      response.redirected_to.should == root_url
      get :edit, { :id => @collection_item.id }, { :user => @collection_editor, :user_id => @collection_editor.id }
      response.rendered[:template].should =~ /collection_items\/edit/ # TODO test JS format response
    end
  end

  # This method is used when JS is disabled, otherwise items are updated through Collection controller
  describe "POST update" do
    it "should update the item if user has permission to update" do
      post :update, :id => @collection_item.id, :collection_item => {:annotation => "New Annotation"}
      response.redirected_to.should == root_url
      getter = lambda{
        post :update, { :id => @collection_item.id, :collection_item => {:annotation => "New Annotation"} },
                      { :user => @collection_editor, :user_id => @collection_editor.id }
        @collection_item.reload
      }
      getter.should change(@collection_item, :annotation)
    end
  end

end
