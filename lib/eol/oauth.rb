module EOL
  module Oauth

    def self.init(provider, options)

      config = YAML.load_file("#{RAILS_ROOT}/config/oauth.yml")[provider]

      case config['type']
      when 'OAuth'
        Oauth1.new(config, options)
      when 'OAuth2'
        Oauth2.new(config, options)
      else
        nil
      end

    end

    class Oauth1
      attr_reader :config
      attr_accessor :callback
      def initialize(config, callback)
        @config = config
        @callback = callback
      end
      def authorize
        'oauth1 test'
      end
    end

    class Oauth2
      attr_reader :config, :client, :code
      attr_accessor :callback, :access_token, :user
      def initialize(config, options)
        @config = config
        @client = OAuth2::Client.new(eval(config['key']), eval(config['secret']), config['params'])
        @callback = options[:callback]
        @code = options[:code]
      end
      
      def authorize_url
        client.auth_code.authorize_url((config['authorize_url_params'] || {}).merge(:redirect_uri => callback))
      end
      
      def access_token
        @access_token = self.client.auth_code.get_token(self.code, (self.config['access_token_params'] || {}).merge(:redirect_uri => self.callback))
      end
      
      def user
        @user
      end
      
      def user=(user_hash = send("#{self.provider}_user_attributes"))
        @user = user_hash
      end
      
    end

    def authenticate(provider, callback)
      config(provider)
      case @config['type']
      when 'OAuth'
        oauth_consumer = consumer(@config)
        request_token = oauth_consumer.get_request_token(:oauth_callback => callback)
        # Save received token and secret in session
        session["#{provider}_request_token_token"] = request_token.token
        session["#{provider}_request_token_secret"] = request_token.secret
        redirect_to request_token.authorize_url
      when 'OAuth2'
        oauth_client = client(@config)
        redirect_to oauth_client.auth_code.authorize_url((@config['authorize_url_params'] || {}).merge(:redirect_uri => callback))
      else
        # Failed to get client information for provider: #{params[:provider]}
        flash[:notice] = I18n.t(:oauth_sign_in_unsuccessful_error)
        return
      end
    end

    def get_user_attributes(callback, options)
      config(options[:provider])
      case @config['type']
      when 'OAuth'
        oauth_consumer = consumer(@config)
        request_token = OAuth::RequestToken.new(oauth_consumer, session["#{options[:provider]}_request_token_token"], session["#{options[:provider]}_request_token_secret"])
        access_token = request_token.get_access_token(:oauth_verifier => options[:oauth_verifier])
      when 'OAuth2'
        oauth_client = client(@config)
        begin
          access_token = oauth_client.auth_code.get_token(options[:code], (@config['access_token_params'] || {}).merge(:redirect_uri => callback))
        rescue
          # TODO: return to the controller with notification for user that access token failed
          return nil
        end
      else
        # Failed to get client information for provider: #{params[:provider]}
        flash[:notice] = I18n.t(:oauth_sign_in_unsuccessful_error)
        return
      end
      # TODO: if access_token.nil? failed to get token
      return send("#{provider}_user_attributes", access_token)
    end

    

    def consumer(config)
      OAuth::Consumer.new(eval(config['key']), eval(config['secret']), config['params'])
    end

    def client(config)
      OAuth2::Client.new(eval(config['key']), eval(config['secret']), config['params'])
    end

    def yahoo_user_attributes(access_token)
      response = access_token.get("http://social.yahooapis.com/v1/user/#{access_token.params[:xoauth_yahoo_guid]}/profile?format=json")
      if response.code == "200"
        authentication_data = JSON.parse(response.body)
        user_attributes = {
          :username => authentication_data['profile']['ims'][0].collect{|k,v| v if k == "handle"}.compact[0],
          :given_name => authentication_data['profile']['givenName'],
          :family_name => authentication_data['profile']['familyName'],
          :authentication_attributes => {
            :provider => "yahoo",
            :guid => authentication_data['profile']['guid'],
            :token => access_token.token,
            :secret => access_token.secret
          }
        }
      end
    end

    def twitter_user_attributes(access_token)
      response = access_token.get("http://twitter.com/account/verify_credentials.json")
      if response.code == "200"
        authentication_data = JSON.parse(response.body)
        user_attributes = {
          :username => authentication_data['screen_name'],
          :authentication_attributes => {
            :provider => "twitter",
            :guid => authentication_data['id'],
            :token => access_token.token,
            :secret => access_token.secret
          }
        }.merge(Hash[ [:given_name, :family_name].zip(authentication_data['name'].split(/\s+/,2)) ])
      end
    end

    def google_user_attributes(access_token)
      response = access_token.get("https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{access_token.token}")
      if response.status == 200
        authentication_data = JSON.parse(response.body)
        user_attributes = {
          :username => authentication_data['email'].split('@').first,
          :given_name => authentication_data['given_name'],
          :family_name => authentication_data['family_name'],
          :email => authentication_data['email'],
          :authentication_attributes => {
            :provider => "google",
            :guid => authentication_data['id'],
            :token => access_token.token
          }
        }
      end
    end

    def facebook_user_attributes(access_token)
      response = access_token.get("https://graph.facebook.com/me?access_token=#{access_token.token}")
      if response.status == 200
        authentication_data = JSON.parse(response.body)
        user_attributes = {
          :username => authentication_data['username'],
          :given_name => authentication_data['first_name'],
          :family_name => authentication_data['last_name'],
          :email => authentication_data['email'],
          :authentication_attributes => {
            :provider => "facebook",
            :guid => authentication_data['id'],
            :token => access_token.token
          }
        }
      end
    end

  end
end
