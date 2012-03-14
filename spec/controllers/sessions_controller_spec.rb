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
      response.redirected_to.should == @user
    end

    context 'extended for open authentication' do

      before :each do
        stub_oauth_requests
      end

      it 'should log in user with Facebook' do
        params_data, session_data = oauth_request_data(:facebook, 2)
        get :new, params_data, session_data
        assigns[:open_auth].should be_a(EOL::OpenAuth::Facebook)
        session[:user_id].should == @connected_user.id
        session[:language_id].should == @connected_user.language_id
        response.redirected_to.should == user_newsfeed_url(@connected_user)
      end
      it 'should log in user with Google' do
        params_data, session_data = oauth_request_data(:google, 2)
        get :new, params_data, session_data
        assigns[:open_auth].should be_a(EOL::OpenAuth::Google)
        session[:user_id].should == @connected_user.id
        session[:language_id].should == @connected_user.language_id
        response.redirected_to.should == user_newsfeed_url(@connected_user)
      end
      it 'should log in user with Twitter' do
        params_data, session_data = oauth_request_data(:twitter)
        get :new, params_data, session_data
        assigns[:open_auth].should be_a(EOL::OpenAuth::Twitter)
        session[:user_id].should == @connected_user.id
        session[:language_id].should == @connected_user.language_id
        response.redirected_to.should == user_newsfeed_url(@connected_user)
      end
      it 'should log in user with Yahoo' do
        params_data, session_data = oauth_request_data(:yahoo)
        get :new, params_data, session_data
        assigns[:open_auth].should be_a(EOL::OpenAuth::Yahoo)
        session[:user_id].should == @connected_user.id
        session[:language_id].should == @connected_user.language_id
        response.redirected_to.should == user_newsfeed_url(@connected_user)
      end

      it 'should redirect user to return_to url after log in' do
        params_data, session_data = oauth_request_data(:yahoo)
        get :new, params_data, session_data.merge(:return_to => taxon_url(1))
        assigns[:open_auth].should be_a(EOL::OpenAuth::Yahoo)
        session[:user_id].should == @connected_user.id
        session[:language_id].should == @connected_user.language_id
        response.redirected_to.should == taxon_url(1)
        flash[:notice].should =~ /login successful/i
      end

      it 'should prevent log in, render new and flash error if oauth account is not connected to an EOL user' do
        open_authentication = @connected_user.open_authentications.select{|oa| oa.provider == 'facebook'}.first
        open_authentication.update_attributes(:provider => 'tempchange')
        params_data, session_data = oauth_request_data(:facebook, 2)
        get :new, params_data, session_data
        assigns[:open_auth].should be_a(EOL::OpenAuth::Facebook)
        session[:user_id].should_not == @connected_user.id
        session[:language_id].should_not == @connected_user.language_id
        response.redirected_to.should == login_url
        flash[:error].should =~ /couldn't find a connection between your Facebook account and EOL/
        open_authentication.update_attributes(:provider => 'facebook')
      end

    end
  end

  describe "POST create" do
    it "should render new with flash error if EOL credentials are invalid" do
      post :create, :session => { :username_or_email => "email@example.com", :password => "invalid" }
      response.redirected_to.should == login_path
      flash[:error].should =~ /login failed/i
    end

    it 'should log in and redirect to user newsfeed if EOL credentials are valid' do
      post :create, :session => { :username_or_email => @user.email, :password => 'password' }
      flash[:notice].should =~ /login successful/i
      response.redirected_to.should == user_newsfeed_url(@user)
    end

    it 'should redirect user to return_to url after log in' do
      post :create, :session => { :username_or_email => @user.email, 
                                  :password => 'password',
                                  :return_to => taxon_url(1) }
      response.redirected_to.should == taxon_url(1)
      flash[:notice].should =~ /login successful/i
    end

    context 'extended for open authentication' do
      it 'should redirect to authorize uri when log in is with Facebook' do
        post :create, { :oauth_provider => 'facebook' }
        response.redirected_to.should =~ /^https:\/\/graph.facebook.com\/oauth\/authorize/
      end
      it 'should redirect to authorize uri when log in is with Google' do
        post :create, { :oauth_provider => 'google' }
        response.redirected_to.should =~ /^https:\/\/accounts.google.com\/o\/oauth2\/auth/
      end
      it 'should redirect to authorize uri when log in is with Twitter' do
        stub_oauth_requests
        post :create, { :oauth_provider => 'twitter' }
        response.redirected_to.should =~ /http:\/\/api.twitter.com\/oauth\/authenticate/
      end
      it 'should redirect to authorize uri when log in is with Yahoo' do
        stub_oauth_requests
        post :create, { :oauth_provider => 'yahoo' }
        response.redirected_to.should =~ /https:\/\/api.login.yahoo.com\/oauth\/v2\/request_auth/
      end
    end
  end

end


