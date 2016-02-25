require "spec_helper"

describe SchemaController do

  before(:all) do
    load_foundation_cache
    @user = User.gen
    @user.grant_permission(:see_data)
  end

  after(:each) do
    session[:user_id] = nil
  end

  describe 'GET terms' do

    it 'should redirect known terms to the glossary' do
      session[:user_id] = @user.id
      known_uri = KnownUri.gen_if_not_exists(:uri => Rails.configuration.uri_term_prefix + 'anything')
      get :terms, :id => 'anything'
      expect(response).to redirect_to(data_glossary_url(:anchor => known_uri.anchor))
      known_uri.destroy
    end

  end

end
