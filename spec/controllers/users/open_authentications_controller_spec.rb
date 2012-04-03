require File.dirname(__FILE__) + '/../../spec_helper'

describe Users::OpenAuthenticationsController do

  before(:all) do
    truncate_all_tables
    Language.create_english
    CuratorLevel.create_defaults
    @user = User.gen
  end

  describe 'POST create should redirect to open authentication provider\'s site for authorization' do

    it 'should redirect to Twitter\'s API site for authorization' do
      session[:user_id] = @user.id
      post :create, :open_authentication => { :provider => "twitter" }, :user_id => @user.id
      assert_redirected_to "http://api.twitter.com/oauth/authenticate?oauth_token=#{session[:twitter_request_token_token]}"
    end

    it 'should redirect to Yahoo\'s API site for authorization' do
      session[:user_id] = @user.id
      post :create, :open_authentication => { :provider => "yahoo" }, :user_id => @user.id
      assert_redirected_to "https://api.login.yahoo.com/oauth/v2/request_auth?oauth_token=#{session[:yahoo_request_token_token]}"
    end

    it 'should redirect to Facebook\'s API site for authorization' do
      open_auth = EOL::OpenAuth.init("facebook", open_authentications_callback_url(:oauth_provider => "facebook"))
      session[:user_id] = @user.id
      post :create, :open_authentication => { :provider => "facebook" }, :user_id => @user.id
      assert_redirected_to open_auth.authorize_uri
    end

    it 'should redirect to Google\'s API website for authorization' do
      open_auth = EOL::OpenAuth.init("google", open_authentications_callback_url(:oauth_provider => "google"))
      session[:user_id] = @user.id
      post :create, :open_authentication => { :provider => "google" }, :user_id => @user.id
      assert_redirected_to open_auth.authorize_uri
    end

  end

end
