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
    # changed the logic of the code
    # it 'should give 404 for unknown terms' do
      # session[:user_id] = @user.id
      # expect { get :terms, :id => 'a_non_existing_uri' }.to raise_error(ActiveRecord::RecordNotFound)
    # end

    it 'should redirect known terms to the glossary' do
      session[:user_id] = @user.id
      known_uri = KnownUri.gen_if_not_exists(:uri => Rails.configuration.uri_term_prefix + 'anything')
      get :terms, :id => 'anything'
      expect(response).to redirect_to(data_glossary_url(:anchor => known_uri.anchor))
      known_uri.destroy
    end

    # not raising an error anymore!
    # it "should only allow access from users who can see_data" do
      # expect { get :terms, :id => 'anything' }.to raise_error(EOL::Exceptions::SecurityViolation)
    # end
  end

end
