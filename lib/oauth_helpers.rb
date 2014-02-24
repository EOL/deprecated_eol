# A module to be *included* that allows some methods for accessing OAuth. You should NOT use this in production, but only in
# administrative tasks like specs and scenarios.
module OauthHelpers

  def oauth_request_data(provider, oauth_protocol = 1)
    case oauth_protocol
    when 1
      params_data = { :oauth_provider => provider.to_s,
                      :oauth_token => 'key',
                      :oauth_verifier => 'verifier' }
      session_data = { "#{provider}_request_token_token" => 'key',
                        "#{provider}_request_token_secret" => 'secret' }
    when 2
      params_data = { :oauth_provider => provider.to_s,
                      :code => 'code' }
      session_data = nil
    end
    return params_data, session_data
  end

  # Fakes responses for external HTTP requests. Requires WebMock gem.
  def stub_oauth_requests
    # Facebook
    stub_request(:post, "https://graph.facebook.com/oauth/access_token").
                to_return(:status => 200,
                          :headers => {'Content-Type' => 'application/x-www-form-urlencoded'},
                          :body => "access_token=key")
    stub_request(:get, "https://graph.facebook.com/me?access_token=key").
                to_return(:status => 200,
                          :headers => {'Content-Type' => 'text/json'},
                          :body => '{ "id": "facebookuserguid",
                                      "email": "facebook@example.com",
                                      "last_name": "FacebookFamily",
                                      "first_name": "FacebookGiven" }')
    # Google
    stub_request(:post, "https://accounts.google.com/o/oauth2/token").
                to_return(:status => 200,
                          :headers => {'Content-Type' => 'application/x-www-form-urlencoded'},
                          :body => "access_token=key")
    stub_request(:get, "https://www.googleapis.com/oauth2/v1/userinfo?access_token=key").
                to_return(:status => 200,
                          :headers => {'Content-Type' => 'text/json'},
                          :body => '{ "id": "googleuserguid",
                                      "email": "google@example.com",
                                      "last_name": "GoogleFamily",
                                      "first_name": "GoogleGiven" }')
    # Twitter
    stub_request(:post, "https://api.twitter.com/oauth/request_token").
                to_return(:status => 200,
                          :headers => {},
                          :body => "oauth_token=key&oauth_token_secret=secret")
    stub_request(:post, "https://api.twitter.com/oauth/access_token").
                to_return(:status => 200,
                          :headers => {},
                          :body => "oauth_token=key&oauth_token_secret=secret")
    stub_request(:get, "https://api.twitter.com/1.1/account/verify_credentials.json").
                to_return(:status => 200,
                          :headers => {},
                          :body => '{ "id": "twitteruserguid",
                                      "name": "TwitterFamily TwitterGiven" }')

    # Yahoo!
    stub_request(:post, "https://api.login.yahoo.com/oauth/v2/get_request_token").
                to_return(:status => 200,
                          :headers => {},
                          :body => "oauth_token=key&oauth_token_secret=secret&xoauth_yahoo_guid=yahoouserguid")
    stub_request(:post, "https://api.login.yahoo.com/oauth/v2/get_token").
                to_return(:status => 200,
                          :headers => {},
                          :body => "oauth_token=key&oauth_token_secret=secret&xoauth_yahoo_guid=yahoouserguid")
    stub_request(:get, "http://social.yahooapis.com/v1/user/yahoouserguid/profile?format=json").
                to_return(:status => 200,
                          :headers => {},
                          :body => '{ "profile": { "guid": "yahoouserguid",
                                                    "familyName": "YahooFamily",
                                                    "givenName": "YahooGiven" }}')
    # Faked OAuth1 provider requests and responses
    stub_request(:post, "http://fake.oauth1.provider/example/access_token_denied").
                  to_return(:status => 401, :headers => {}, :body => "")
    stub_request(:any, "http://fake.oauth1.provider/example/request_token").
                to_return(:status => 200,
                          :headers => {},
                          :body => "oauth_token=key&oauth_token_secret=secret")
    stub_request(:post, "http://fake.oauth1.provider/example/access_token").
                to_return(:status => 200,
                          :headers => {},
                          :body => "oauth_token=key&oauth_token_secret=secret")
    # Faked OAuth2 provider requests and responses
    stub_request(:post, "https://fake.oauth2.provider/example/access_token").
                to_return(:status => 200,
                          :headers => {'Content-Type' => 'application/x-www-form-urlencoded'},
                          :body => "access_token=key")
  end

end
