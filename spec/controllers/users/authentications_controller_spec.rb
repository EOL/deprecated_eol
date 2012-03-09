require File.dirname(__FILE__) + '/../../spec_helper'

describe Users::AuthenticationsController do

  describe 'POST authenticate' do

    it 'should redirect to Twitter\'s API site for authorization' do
      post :authenticate, :provider => "twitter"
      assert_redirected_to "http://api.twitter.com/oauth/authenticate?oauth_token=#{session[:twitter_request_token_token]}"
    end

    it 'should redirect to Yahoo\'s API site for authorization' do
      post :authenticate, :provider => "yahoo"
      assert_redirected_to "https://api.login.yahoo.com/oauth/v2/request_auth?oauth_token=#{session[:yahoo_request_token_token]}"
    end

    it 'should redirect to Facebook\'s API site for authorization'

    it 'should redirect to Google\'s API website for authorization'

  end

end
