require File.dirname(__FILE__) + '/../spec_helper'

describe SessionsController do

  before(:all) do
    unless (@user = User.find_by_username('session_controller_spec')) &&
           (@connected_user = User.find_by_username('oauth_session_controller_spec'))
      truncate_all_tables
      Language.create_english
      CuratorLevel.create_defaults
      @user = User.gen(:username => 'session_controller_spec', :password => 'password')
      @connected_user = User.gen(:username => 'oauth_session_controller_spec')
      @connected_user.open_authentications_attributes = [{ :provider => 'facebook',
                                                           :guid => 'facebookuserguid' },
                                                         { :provider => 'google',
                                                           :guid => 'googleuserguid' },
                                                         { :provider => 'twitter',
                                                           :guid => 'twitteruserguid' },
                                                         { :provider => 'yahoo',
                                                           :guid => 'yahoouserguid' }]
      @connected_user.save
    end
  end

  describe "GET new" do

    it 'should be successful' do
      get :new
      response.should be_success
    end
    it 'should redirect to user show if user is logged in' do
      get :new, nil, {:user_id => @user.id}
      expect(response).to redirect_to(@user)
    end

    context 'extended for open authentication' do
      it 'should clear obsolete session data from different provider' do
        params_data, session_data = oauth_request_data(:twitter)
        get :new, { :oauth_provider => 'facebook' }, session_data
        session_data.each{|k,v| session.include?(k).should be_false}
      end
      it 'should redirect to authorize uri before log in with Facebook' do
        get :new, { :oauth_provider => 'facebook' }
        response.header['Location'].should =~ /^https:\/\/graph.facebook.com\/oauth\/authorize/
      end
      it 'should redirect to authorize uri before log in with Google' do
        post :new, { :oauth_provider => 'google' }
        response.header['Location'].should =~ /^https:\/\/accounts.google.com\/o\/oauth2\/auth/
      end
      it 'should redirect to authorize uri before log in with Twitter' do
        stub_oauth_requests
        post :new, { :oauth_provider => 'twitter' }
        response.header['Location'].should =~ /http:\/\/api.twitter.com\/oauth\/authenticate/
      end
      it 'should redirect to authorize uri before log with Yahoo' do
        stub_oauth_requests
        post :new, { :oauth_provider => 'yahoo' }
        response.header['Location'].should =~ /https:\/\/api.login.yahoo.com\/oauth\/v2\/request_auth/
      end
      it 'should redirect and flash error if user denies access when logging in with Twitter' do
        oauth1_consumer = OAuth::Consumer.new("key", "secret", {
          :site => "http://fake.oauth1.provider",
          :request_token_path => "/example/request_token",
          :access_token_path => "/example/access_token_denied",
          :authorize_path => "/example/authorize" })
        OAuth::Consumer.should_receive(:new).and_return(oauth1_consumer)
        get :new, {:denied => "key",
                   :oauth_provider => 'twitter'},
                  { "twitter_request_token_token" => 'key',
                    "twitter_request_token_secret" => 'secret',
                    "return_to" => collection_url(1) }
        assigns[:open_auth].should be_a(EOL::OpenAuth::Twitter)
        expect(response).to redirect_to(collection_url(1))
        flash[:error].should match /Sorry, we are not authorized.+?Twitter/
      end
      it 'should redirect and flash error if user denies access when logging in with Facebook' do
        get :new, { :error => "access_denied", :oauth_provider => 'facebook' }, { :return_to => collection_url(1) }
        assigns[:open_auth].should be_a(EOL::OpenAuth::Facebook)
        expect(response).to redirect_to(collection_url(1))
        flash[:error].should match /Sorry, we are not authorized.+?Facebook/
      end
      it 'should redirect and flash error if user denies access when logging in with Google' do
        get :new, { :error => "access_denied", :oauth_provider => 'google' }, { :return_to => collection_url(1) }
        assigns[:open_auth].should be_a(EOL::OpenAuth::Google)
        expect(response).to redirect_to(collection_url(1))
        flash[:error].should match /Sorry, we are not authorized.+?Google/
      end
      it 'should prevent log in, render new and flash error if oauth account is not connected to an EOL user' do
        stub_oauth_requests
        open_authentication = @connected_user.open_authentications.select{|oa| oa.provider == 'facebook'}.first
        open_authentication.update_attributes(:provider => 'tempchange')
        params_data, session_data = oauth_request_data(:facebook, 2)
        get :new, params_data, session_data
        assigns[:open_auth].should be_a(EOL::OpenAuth::Facebook)
        session[:user_id].should_not == @connected_user.id
        session[:language_id].should_not == @connected_user.language_id
        expect(response).to redirect_to(login_url)
        flash[:error].should =~ /couldn't find a connection between your Facebook account and EOL/
        open_authentication.update_attributes(:provider => 'facebook')
     end
     it 'should log in user with Facebook' do
        stub_oauth_requests
        params_data, session_data = oauth_request_data(:facebook, 2)
        get :new, params_data, session_data
        assigns[:open_auth].should be_a(EOL::OpenAuth::Facebook)
        session[:user_id].should == @connected_user.id
        session[:language_id].should == @connected_user.language_id
        expect(response).to redirect_to(user_newsfeed_url(@connected_user))
      end
      it 'should log in user with Google' do
        stub_oauth_requests
        params_data, session_data = oauth_request_data(:google, 2)
        get :new, params_data, session_data
        assigns[:open_auth].should be_a(EOL::OpenAuth::Google)
        session[:user_id].should == @connected_user.id
        session[:language_id].should == @connected_user.language_id
        expect(response).to redirect_to(user_newsfeed_url(@connected_user))
      end
      it 'should log in user with Twitter' do
        stub_oauth_requests
        params_data, session_data = oauth_request_data(:twitter)
        get :new, params_data, session_data
        assigns[:open_auth].should be_a(EOL::OpenAuth::Twitter)
        session[:user_id].should == @connected_user.id
        session[:language_id].should == @connected_user.language_id
        expect(response).to redirect_to(user_newsfeed_url(@connected_user))
      end
      it 'should log in user with Yahoo' do
        stub_oauth_requests
        params_data, session_data = oauth_request_data(:yahoo)
        get :new, params_data, session_data
        assigns[:open_auth].should be_a(EOL::OpenAuth::Yahoo)
        session[:user_id].should == @connected_user.id
        session[:language_id].should == @connected_user.language_id
        expect(response).to redirect_to(user_newsfeed_url(@connected_user))
      end

      it 'should redirect user to return to url after log in' do
        stub_oauth_requests
        params_data, session_data = oauth_request_data(:yahoo)
        get :new, params_data, session_data.merge(:return_to => taxon_url(1))
        assigns[:open_auth].should be_a(EOL::OpenAuth::Yahoo)
        session[:user_id].should == @connected_user.id
        session[:language_id].should == @connected_user.language_id
        expect(response).to redirect_to(taxon_url(1))
        flash[:notice].should =~ /login successful/i
      end

    end
  end

  describe "POST create" do
    it "should render new with flash error if EOL credentials are invalid" do
      post :create, :session => { :username_or_email => "email@example.com", :password => "invalid" }
      expect(response).to redirect_to(login_path)
      flash[:error].should =~ /login failed/i
    end

    it 'should log in and redirect to user newsfeed if EOL credentials are valid' do
      post :create, :session => { :username_or_email => @user.email, :password => 'password' }
      flash[:notice].should =~ /login successful/i
      expect(response).to redirect_to(user_newsfeed_url(@user))
    end

    it 'should redirect user to return_to url after log in' do
      post :create, :session => { :username_or_email => @user.email, 
                                  :password => 'password',
                                  :return_to => taxon_url(1) }
      expect(response).to redirect_to(taxon_url(1))
      flash[:notice].should =~ /login successful/i
    end

  end

end


