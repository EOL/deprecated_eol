require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionsController do

  before(:all) do
    # so this part of the before :all runs only once
    unless User.find_by_username('collections_scenario')
      truncate_all_tables
      load_scenario_with_caching(:collections)
    end
    @test_data  = EOL::TestInfo.load('collections')
    @collection = @test_data[:collection]
    EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
  end

  describe 'GET show' do
    it 'should set view as options and currently selected view' do
      get :show, :id => @collection.id
      assigns[:view_as].should == @collection.default_view_style
      assigns[:view_as_options].should == [ViewStyle.list, ViewStyle.gallery, ViewStyle.annotated]
      get :show, :id => @collection.id, :view_as => ViewStyle.gallery.id
      assigns[:view_as].should == ViewStyle.gallery
    end
  end

  describe 'GET edit' do
    it 'should set view as options' do
      get :edit, { :id => @collection.id }, { :user_id => @collection.users.first.id, :user => @collection.users.first }
      assigns[:view_as_options].should == [ViewStyle.list, ViewStyle.gallery, ViewStyle.annotated]
    end
  end

  describe "#update" do
    it "When not logged in, users cannot update the description" do
      session[:user_id] = nil
      lambda { post :update, :id => @collection.id, :commit_edit_collection => 'Submit',
                             :collection => {:description => "New Description"}
      }.should raise_error(EOL::Exceptions::MustBeLoggedIn)
    end
    it "Unauthorized users cannot update the description" do
      user = User.gen
      lambda {
        session[:user_id] = user.id
        post :update, { :id => @collection.id, :commit_edit_collection => 'Submit',
                        :collection => {:description => "New Description"} },
                      { :user => user, :user_id => user.id }
      }.should raise_error(EOL::Exceptions::SecurityViolation)

    end
    it "Updates the description" do
      getter = lambda{
        session[:user_id] = @test_data[:user].id
        post :update, :id => @collection.id, :commit_edit_collection => 'Submit',  :collection => {:description => "New Description"}
        @collection.reload
      }
      getter.should change(@collection, :description)
    end

  end

end
