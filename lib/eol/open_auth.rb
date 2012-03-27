module EOL
  module OpenAuth

    def self.config_file
      @config_file ||= YAML.load_file("#{RAILS_ROOT}/config/oauth.yml")
    end

    def self.init(provider, callback, options = { :code => nil,
                                                  :request_token_token => nil,
                                                  :request_token_secret => nil,
                                                  :oauth_verifier => nil })
      case provider
      when 'facebook'
        # fix this
        OpenAuthFacebook.new(config_file['facebook'], callback, options[:code])
      when 'google'
        OpenAuthGoogle.new(config_file['google'], callback, options[:code])
      when 'twitter'
        OpenAuthTwitter.new(config_file['twitter'], callback, options[:request_token_token], options[:request_token_secret], options[:oauth_verifier])
      when 'yahoo'
        OpenAuthYahoo.new(config_file['yahoo'], callback, options[:request_token_token], options[:request_token_secret], options[:oauth_verifier])
      end
    end

    # Parent class for Open Authentications shared attributes and methods for both OpenAuth1 and OpenAuth2 protocols.
    class OpenAuth

      attr_accessor :config, :callback, :client, :authorize_uri, :provider
      attr_writer :access_token, :basic_info_uri, :basic_info, :basic_info_parsed,
                  :user_attributes, :authentication_attributes

      def initialize(provider, config, callback)
        @provider = provider
        @config = config
        @callback = callback
      end
      
      def basic_info
        @basic_info ||= access_token.get(basic_info_uri)
      end

      def basic_info_parsed
        @basic_info_parsed ||= parse_response(basic_info)
      end

      def parse_response(response)
        return nil unless (response.respond_to?(:code) && response.code == "200") || 
                          (response.respond_to?(:status) && response.status == 200)
        JSON.parse(response.body)
      end

    end

    # Shared attributes and methods for OAuth service providers using OAuth1 protocol.
    class OpenAuth1 < OpenAuth

      attr_accessor :request_token, :verifier
      attr_writer :session_data

      def initialize(provider, config, callback, request_token_token = nil, request_token_secret = nil, verifier = nil)
        super(provider, config, callback)
        # use const_get instead of eval
        @client = OAuth::Consumer.new(eval(config['key']), eval(config['secret']), config['params'].dup)
        @verifier = verifier
        if request_token_token && request_token_secret
          @request_token = OAuth::RequestToken.new(client, request_token_token, request_token_secret)
        else
          @request_token = client.get_request_token(:oauth_callback => callback)
          @authorize_uri = request_token.authorize_url
        end
      end

      def session_data
        @session_data ||= { "#{provider}_request_token_token" => request_token.token,
                            "#{provider}_request_token_secret" => request_token.secret }
      end

      def access_token
        @access_token ||= request_token.get_access_token(:oauth_verifier => verifier)
      end

    end

    # Shared attributes and methods for OAuth servers using OAuth2 protocol.
    class OpenAuth2 < OpenAuth

      attr_reader :code

      def initialize(provider, config, callback, code = nil)
        super(provider, config, callback)
        @client = OAuth2::Client.new(eval(config['key']), eval(config['secret']), config['params'].dup)
        @authorize_uri = client.auth_code.authorize_url((config['authorize_url_params'] || {}).merge(:redirect_uri => callback))
        @code = code
      end

      def access_token
        @access_token ||= client.auth_code.get_token(code, (config['access_token_params'] || {}).merge(:redirect_uri => callback))
      end

    end

    class OpenAuthFacebook < OpenAuth2

      def initialize(config, callback, code = nil)
        super('facebook', config, callback, code)
      end

      def basic_info_uri
        @basic_info_uri ||= "https://graph.facebook.com/me?access_token=#{access_token.token}"
      end

      def user_attributes
        @user_attributes ||= { :username => basic_info_parsed['username'],
                               :given_name => basic_info_parsed['first_name'],
                               :family_name => basic_info_parsed['last_name'],
                               :email => basic_info_parsed['email']}
      end

      def authentication_attributes
        @authentication_attributes ||= { :guid => basic_info_parsed['id'],
                                         :provider => provider,
                                         :token => access_token.token }
      end
    end

    class OpenAuthGoogle < OpenAuth2

      def initialize(config, callback, code = nil)
        super('google', config, callback, code)
      end

      def basic_info_uri
        @basic_info_uri ||= "https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{access_token.token}"
      end

      def user_attributes
        @user_attributes ||= { :username => basic_info_parsed['email'].split('@').first,
                               :given_name => basic_info_parsed['given_name'],
                               :family_name => basic_info_parsed['family_name'],
                               :email => basic_info_parsed['email']}
      end

      def authentication_attributes
        @authentication_attributes ||= { :guid => basic_info_parsed['id'],
                                         :provider => provider,
                                         :token => access_token.token }
      end

    end

    class OpenAuthTwitter < OpenAuth1

      def initialize(config, callback, request_token_token = nil, request_token_secret = nil, verifier = nil)
        super('twitter', config, callback, request_token_token, request_token_secret, verifier)
      end

      def basic_info_uri
        @basic_info_uri ||= "http://twitter.com/account/verify_credentials.json"
      end

      def user_attributes
        @user_attributes ||= { :username => basic_info_parsed['screen_name'] }.merge(Hash[ [:given_name, :family_name].zip(basic_info_parsed['name'].split(/\s+/,2)) ])
      end

      def authentication_attributes
        @authentication_attributes ||= { :guid => basic_info_parsed['id'],
                                         :provider => provider,
                                         :token => access_token.token,
                                         :secret => access_token.secret }
      end
    end

    class OpenAuthYahoo < OpenAuth1

      def initialize(config, callback, request_token_token = nil, request_token_secret = nil, verifier = nil)
        super('yahoo', config, callback, request_token_token, request_token_secret, verifier)
      end

      def basic_info_uri
        @basic_info_uri ||= "http://social.yahooapis.com/v1/user/#{access_token.params[:xoauth_yahoo_guid]}/profile?format=json"
      end

      def user_attributes
        @user_attributes ||= { :username => basic_info_parsed['profile']['ims'][0].collect{|k,v| v if k == "handle"}.compact[0],
                               :given_name => basic_info_parsed['profile']['givenName'],
                               :family_name => basic_info_parsed['profile']['familyName']}
      end

      def authentication_attributes
        @authentication_attributes ||= { :guid => basic_info_parsed['profile']['guid'],
                                         :provider => provider,
                                         :token => access_token.token,
                                         :secret => access_token.secret }
      end
    end

  end
end





#    def authenticate(provider, callback)
#      config(provider)
#      case @config['type']
#      when 'OAuth'
#        oauth_consumer = consumer(@config)
#        request_token = oauth_consumer.get_request_token(:oauth_callback => callback)
#        # Save received token and secret in session
#        session["#{provider}_request_token_token"] = request_token.token
#        session["#{provider}_request_token_secret"] = request_token.secret
#        redirect_to request_token.authorize_url
#      when 'OAuth2'
#        oauth_client = client(@config)
#        redirect_to oauth_client.auth_code.authorize_url((@config['authorize_url_params'] || {}).merge(:redirect_uri => callback))
#      else
#        # Failed to get client information for provider: #{params[:provider]}
#        flash[:notice] = I18n.t(:oauth_sign_in_unsuccessful_error)
#        return
#      end
#    end
#
#    def get_user_attributes(callback, options)
#      config(options[:provider])
#      case @config['type']
#      when 'OAuth'
#        oauth_consumer = consumer(@config)
#        request_token = OAuth::RequestToken.new(oauth_consumer, session["#{options[:provider]}_request_token_token"], session["#{options[:provider]}_request_token_secret"])
#        access_token = request_token.get_access_token(:oauth_verifier => options[:oauth_verifier])
#      when 'OAuth2'
#        oauth_client = client(@config)
#        begin
#          access_token = oauth_client.auth_code.get_token(options[:code], (@config['access_token_params'] || {}).merge(:redirect_uri => callback))
#        rescue
#          # TODO: return to the controller with notification for user that access token failed
#          return nil
#        end
#      else
#        # Failed to get client information for provider: #{params[:provider]}
#        flash[:notice] = I18n.t(:oauth_sign_in_unsuccessful_error)
#        return
#      end
#      # TODO: if access_token.nil? failed to get token
#      return send("#{provider}_user_attributes", access_token)
#    end
#
#
#
#




