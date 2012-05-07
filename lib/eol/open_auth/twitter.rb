module EOL
  module OpenAuth
    class Twitter < EOL::OpenAuth::Protocol1

      def initialize(callback, request_token_token = nil, request_token_secret = nil, verifier = nil)
        super('twitter', EOL::OpenAuth.config_file['twitter'], callback, request_token_token, request_token_secret, verifier)
      end

      def basic_info
        @basic_info ||= get_data("http://twitter.com/account/verify_credentials.json")
      end

      def user_attributes
        @user_attributes ||= Hash[ [:given_name, :family_name].zip(basic_info['name'].split(/\s+/,2)) ]
      end

      def authentication_attributes
        @authentication_attributes ||= { :guid => basic_info['id'],
                                         :provider => provider,
                                         :token => access_token.token,
                                         :secret => access_token.secret }
      end
    end

  end
end

