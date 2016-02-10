require "spec_helper"

describe CollectionsController do
  render_views
  before(:all) do
    truncate_all_tables
    load_foundation_cache
    @user = User.gen
    @collection = Collection.gen
    @collection.users<<@user
    EOL::Solr::CollectionItemsCoreRebuilder.begin_rebuild
  end

  describe 'GET show' do
    it 'should set view as options and currently selected view' do
      get :show, :id => @collection.id
      assigns[:view_as].should == @collection.view_style_or_default
      assigns[:view_as_options].should == [ViewStyle.list, ViewStyle.gallery, ViewStyle.annotated]
      get :show, :id => @collection.id, :view_as => ViewStyle.gallery.id
      assigns[:view_as].should == ViewStyle.gallery
    end
    describe '#login_with_open_authentication' do
      it 'should do nothing unless oauth_provider param is present' do
        get :show, :id => @collection.id
        response.status.should == 200
        response.should render_template('collections/show')
      end
      it 'should redirect to login unless user already logged in' do
        provider = 'aprovider'
        get :show, { :id => @collection.id, :oauth_provider => provider }
        session[:return_to].should == collection_url(@collection)
        expect(response).to redirect_to(login_url(:oauth_provider => provider))
        get :show, { :id => @collection.id, :oauth_provider => provider }, { :user_id => @user.id }
        response.should_not redirect_to(login_url(:oauth_provider => provider))
      end
      it 'should redirect to current url if it matches the session return to url and clear obsolete session data' do
        obsolete_oauth_session_data = {:provider_request_token_token => 'token',
                                       :provider_request_token_secret => 'secret',
                                       :provider_oauth_state => 'state'}
        return_to_url = collection_url(@collection)
        get :show, { :id => @collection.id, :oauth_provider => 'provider' },
                   obsolete_oauth_session_data.merge({ :return_to => return_to_url })
        obsolete_oauth_session_data.each{|k,v| session.has_key?(k.to_s).should be_false}
        expect(response).to redirect_to(return_to_url)
      end
    end
  end

  describe 'GET edit' do
    it 'should set view as options' do
      session[:user_id] = nil
      get :edit, { :id => @collection.id }, { :user_id => @user.id, :user => @user }
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
      session[:user_id] = nil
      getter = lambda{
        session[:user_id] = @user.id
        post :update, :id => @collection.id, :commit_edit_collection => 'Submit',  :collection => {:description => "New Description"}
        @collection.reload
      }
      getter.should change(@collection, :description)
    end

  end

  describe '#choose_collect_target' do

    let(:user) { build_stubbed(User) }
    let(:watch_collection) {build_stubbed(Collection, updated_at: 1.day.ago, user: user)}
    let(:c1) { build_stubbed(Collection, updated_at: 1.week.ago, user: user) }
    let(:c2) { build_stubbed(Collection, updated_at: 1.year.ago, user: user) }
    let(:item) { build_stubbed(TaxonConcept) }

    before do
      allow(controller).to receive(:current_user) { user }
      allow(controller).to receive(:logged_in?) { true }
      allow(TaxonConcept).to receive(:find) { item }
      allow(user).to receive(:watch_collection) { watch_collection }
    end

    it 'displays the collections according to the recently updated' do
      allow(user).to receive(:all_collections) {[ watch_collection, c1, c2 ]}
       get :choose_collect_target, item_id: item.id, item_type: "TaxonConcept"
      expect( assigns[:collections].reject{ |c| c.id == watch_collection.id } ).to eq [ c1, c2 ]

      c3 =  build_stubbed(Collection, updated_at: 1.second.ago, user: user) 
      allow(user).to receive(:all_collections) {[ watch_collection, c1, c2 , c3]}
      get :choose_collect_target, item_id: item.id, item_type: "TaxonConcept"
      expect( assigns[:collections].reject{ |c| c.id == watch_collection.id } ).to eq [ c3, c1, c2 ]
    end
  end
end
