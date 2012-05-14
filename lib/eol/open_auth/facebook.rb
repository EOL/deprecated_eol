module EOL
  module OpenAuth
    class Facebook < EOL::OpenAuth::Protocol2

      def initialize(callback, code = nil, state = nil, stored_state = nil, error = nil)
        super('facebook', EOL::OpenAuth.config_file['facebook'], callback, code, state, stored_state, error)
      end

      def basic_info
        @basic_info ||= get_data("https://graph.facebook.com/me?access_token=#{access_token.token}")
      end

      def user_attributes
        @user_attributes ||= { :given_name => basic_info['first_name'],
                               :family_name => basic_info['last_name'],
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

