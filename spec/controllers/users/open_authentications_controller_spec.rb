require File.dirname(__FILE__) + '/../../spec_helper'

describe Users::OpenAuthenticationsController do

  before(:all) do
    truncate_all_tables
    Language.create_english
    CuratorLevel.create_defaults
    @user = User.gen
  end

  describe 'GET index' do
    it 'should only be accessible by self and administrators' do
      admin = User.gen(:admin => true)
      get :index, {:user_id => @user.id}, {:user_id => @user.id}
      assigns[:user].should == @user
      response.rendered[:template].should == 'users/open_authentications/index.html.haml'
      expect { get :index, {:user_id => @user.id}, {:user_id => User.id * 99} }.to
        raise_error(EOL::Exceptions::SecurityViolation)
      expect { get :index, {:user_id => @user.id}, {:user_id => admin.id}  }.to
        raise_error(EOL::Exceptions::SecurityViolation)
      expect { get :index, {:user_id => @user.id} }.to
        raise_error(EOL::Exceptions::SecurityViolation)
    end
  end

  describe 'GET new' do
    it 'should redirect to index unless we have an oauth provider param' do
      get :new, {:user_id => @user.id}, {:user_id => @user.id}
      response.redirected_to.should == user_open_authentications_url(@user.id)
    end
    it 'should only be accessible by self or admin' do
      admin = User.gen(:admin => true)
      expect { get :new, { :user_id => @user.id, :oauth_prover => 'provider'}, { :user_id => @user.id } }.to_not
        raise_error(EOL::Exceptions::SecurityViolation)
      expect { get :new, { :user_id => @user.id, :oauth_prover => 'provider'}, { :user_id => admin } }.to_not
        raise_error(EOL::Exceptions::SecurityViolation)
      expect { get :new, { :user_id => @user.id, :oauth_prover => 'provider' } }.to
        raise_error(EOL::Exceptions::SecurityViolation)
      expect { get :new, { :user_id => @user.id, :oauth_prover => 'provider'}, { :user_id => @user.id * 99 } }.to
        raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should redirect to authorize uri when adding connection to Facebook' do
      get :new, { :user_id => @user.id, :oauth_provider => 'facebook' }, {:user_id => @user.id}
      response.redirected_to.should =~ /^https:\/\/graph.facebook.com\/oauth\/authorize/
    end
    it 'should redirect to authorize uri when adding connection to Google' do
      get :new, { :user_id => @user.id, :oauth_provider => 'google' }, {:user_id => @user.id}
      response.redirected_to.should =~ /^https:\/\/accounts.google.com\/o\/oauth2\/auth/
    end
    it 'should redirect to authorize uri when adding connection to Twitter' do
      stub_oauth_requests
      get :new, { :user_id => @user.id, :oauth_provider => 'twitter' }, {:user_id => @user.id}
      response.redirected_to.should =~ /http:\/\/api.twitter.com\/oauth\/authenticate/
    end
    it 'should redirect to authorize uri when adding connection to Yahoo' do
      stub_oauth_requests
      get :new, { :user_id => @user.id, :oauth_provider => 'yahoo' }, {:user_id => @user.id}
      response.redirected_to.should =~ /https:\/\/api.login.yahoo.com\/oauth\/v2\/request_auth/
    end

  end

  describe 'POST create' do
    it 'should do some stuff'

  end

  describe 'POST destroy' do
    it 'should do some stuff'

  end
end
