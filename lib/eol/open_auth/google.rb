module EOL
  module OpenAuth
    class Google < EOL::OpenAuth::Protocol2

      def initialize(callback, code = nil)
        super('google', EOL::OpenAuth.config_file['google'], callback, code)
      end

      def basic_info
        @basic_info ||= get_data("https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{access_token.token}")
      end

      def user_attributes
        @user_attributes ||= { :given_name => basic_info['given_name'],
                               :family_name => basic_info['family_name'],
                               :email => basic_info['email']}
      end

      def authentication_attributes
        @authentication_attributes ||= { :guid => basic_info['id'],
                                         :provider => provider,
                                         :token => access_token.token }
      end

    end

  end
end

