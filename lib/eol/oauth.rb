module EOL
  class Oauth

    def self.consumer(config)
      OAuth::Consumer.new(eval(config['key']), eval(config['secret']), config['params'])
    end

    def self.consumer2(config)
      OAuth2::Client.new(eval(config['key']), eval(config['secret']), config['params'])
    end

    def self.profile(provider, access_token)
      send("#{provider}_profile", access_token)
    end

    def self.yahoo_profile(access_token)
      response = access_token.get("http://social.yahooapis.com/v1/user/#{access_token.params[:xoauth_yahoo_guid]}/profile?format=json")
      if response.code == "200"
        authentication_data = JSON.parse(response.body)
        user_info = {
          :provider => "yahoo",
          :user_name => authentication_data['profile']['ims'][0].collect{|k,v| v if k == "handle"}.compact[0],
          :given_name => authentication_data['profile']['givenName'],
          :family_name => authentication_data['profile']['familyName'],
          :full_name => [authentication_data['profile']['givenName'], authentication_data['profile']['familyName']].join(' ').strip,
          :guid => authentication_data['profile']['guid'],
          :token => access_token.token,
          :secret => access_token.secret
        }
      end
    end

    def self.twitter_profile(access_token)
      response = access_token.get("http://twitter.com/account/verify_credentials.json")
      if response.code == "200"
        authentication_data = JSON.parse(response.body)
        user_info = {
          :provider => "twitter",
          :user_name => authentication_data['screen_name'],
          :full_name => authentication_data['name'],
          :guid => authentication_data['id'],
          :token => access_token.token,
          :secret => access_token.secret
        }
      end
    end

    def self.google_profile(access_token)
      response = access_token.get("https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{access_token.token}")
      if response.status == 200
        authentication_data = JSON.parse(response.body)
        user_info = {
          :provider => "google",
          :user_name => authentication_data['email'],
          :given_name => authentication_data['given_name'],
          :family_name => authentication_data['family_name'],
          :full_name => authentication_data['name'],
          :email => authentication_data['email'],
          :guid => authentication_data['id'],
          :token => access_token.token,
          :secret => ''
        }
      end
    end

    def self.facebook_profile(access_token)
      response = access_token.get("https://graph.facebook.com/me?access_token=#{access_token.token}")
      if response.status == 200
        authentication_data = JSON.parse(response.body)
        user_info = {
          :provider => "facebook",
          :user_name => authentication_data['email'],
          :given_name => authentication_data['first_name'],
          :family_name => authentication_data['last_name'],
          :full_name => authentication_data['name'],
          :email => authentication_data['email'],
          :guid => authentication_data['id'],
          :token => access_token.token,
          :secret => ''
        }
      end
    end

  end
end
