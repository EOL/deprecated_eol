require 'spec_helper'

describe CuratorsSuggestedSearchesController do

  before(:all) do
    load_foundation_cache
    @master = FactoryGirl.create(:master_curator)
    @user = User.gen
    @mass = KnownUri.gen_if_not_exists( uri: Rails.configuration.uri_term_prefix + 'mass', name: 'Mass', uri_type_id: UriType.measurement.id )
    @suggested_searches = []
    3.times{@suggested_searches << CuratorsSuggestedSearch.create(label: "any new label", uri: @mass.uri)}
  end

  describe 'GET new' do

    it 'should be restricted to master curators' do
      session[:user_id] = @user.id
      expect { get :new, { curators_suggested_search: {label: "any label", uri: @mass.uri}, user: @user} }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'renders new if master curator' do
      session[:user_id] = @master.id
      get :new, user: @master
      expect(response).to render_template(:new)
    end
  end

  describe 'POST create' do

    it 'should be restricted to master curators' do
      session[:user_id] = @user.id
      expect { post :create, { curators_suggested_search:{label: "any label", uri: @mass.uri}, user: @user} }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'redirects to the data_search page after creation' do
      session[:user_id] = @master.id
       post :create,  {curators_suggested_search: {label: "any label", uri: @mass.uri} , user: @master}
      expect(response).to redirect_to(data_search_path)
    end

    it 're-render new if label is empty' do
      session[:user_id]= @master.id
      suggested_search = CuratorsSuggestedSearch.new( uri: @mass.uri)
      post :create, {curators_suggested_search:  {uri: @mass.uri }, user: @master}
      expect(response).to render_template(:new)
      expect(flash[:error]).to eq I18n.t "curators_suggested_searches.empty_label_error"
    end
  end

  describe 'DELETE destroy' do
    it 'should be restricted to master curators' do
      expect { delete :destroy, { curators_suggested_search: @suggested_searches.first, user: @user} }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

     it 'redirects to data_search page after deletion' do
       session[:user_id] = @master.id
       delete :destroy, { id: @suggested_searches.first, user: @master}
       expect(response).to redirect_to data_search_path
    end
  end

end
