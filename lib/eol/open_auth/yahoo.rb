module EOL
  module OpenAuth
    class Yahoo < EOL::OpenAuth::Protocol1

      def initialize(callback, request_token_token = nil, request_token_secret = nil, verifier = nil, denied = nil)
        super('yahoo', EOL::OpenAuth.config_file['yahoo'], callback, request_token_token, request_token_secret,
              verifier, denied)
      end

      def basic_info
        @basic_info ||= get_data("http://social.yahooapis.com/v1/user/#{access_token.params[:xoauth_yahoo_guid]}/profile?format=json")
      end

      def user_attributes
        @user_attributes ||= { :given_name => basic_info['profile']['givenName'],
                               :family_name => basic_info['profile']['familyName']}
      end

      def authentication_attributes
        @authentication_attributes ||= { :guid => basic_info['profile']['guid'],
                                         :provider => provider,
                                         :token => access_token.token,
                                         :secret => access_token.secret }
      end
    end

  end
end

