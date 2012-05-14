require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionsController do

  before(:all) do
    # so this part of the before :all runs only once
    unless @user = User.find_by_username('collections_scenario')
      truncate_all_tables
      load_scenario_with_caching(:collections)
      @user = User.find_by_username('collections_scenario')
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
    describe '#login_with_open_authentication' do
      it 'should do nothing unless oauth_provider param is present' do
        get :show, :id => @collection.id
        response.redirected_to.should be_nil
        response.rendered[:template].should == 'collections/show.html.haml'
      end
      it 'should redirect to login unless user already logged in' do
        provider = 'aprovider'
        get :show, { :id => @collection.id, :oauth_provider => provider }
        session[:return_to].should == collection_url(@collection)
        response.redirected_to.should == login_url(:oauth_provider => provider)
        get :show, { :id => @collection.id, :oauth_provider => provider }, { :user_id => @user.id }
        response.redirected_to.should_not == login_url(:oauth_provider => provider)
      end
      it 'should redirect to current url if it matches the session return to url and clear obsolete session data' do
        obsolete_oauth_session_data = {:provider_request_token_token => 'token',
                                       :provider_request_token_secret => 'secret',
                                       :provider_oauth_state => 'state'}
        return_to_url = collection_url(@collection)
        get :show, { :id => @collection.id, :oauth_provider => 'provider' },
                   obsolete_oauth_session_data.merge({ :return_to => return_to_url })
        obsolete_oauth_session_data.each{|k,v| session.has_key?(k.to_s).should be_false}
        response.redirected_to.should == return_to_url
      end
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
