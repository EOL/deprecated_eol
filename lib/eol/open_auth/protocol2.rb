module EOL
  module OpenAuth
    # Shared attributes and methods for OAuth servers using OAuth 2 protocol.
    class Protocol2 < EOL::OpenAuth::Base

      attr_reader :code, :error, :state, :stored_state
      attr_writer :state

      def initialize(provider, config, callback, code = nil, state = nil, stored_state = nil, error = nil)
        super(provider, config, callback)
        # TODO: Replace eval with some other solution - const_get doesn't seem to work for environment vars
        @client = OAuth2::Client.new(eval(config['key']), eval(config['secret']), config['params'].dup)
        @code = code
        @state = state
        @stored_state = stored_state
        @error = error
      end

      def authorize_uri
        @authorize_uri = client.auth_code.authorize_url((config['authorize_url_params'] || {}).merge(
                         :redirect_uri => callback))
      end

      def access_token
        @access_token ||= client.auth_code.get_token(code, (config['access_token_params'] || {}).merge(
                          :redirect_uri => callback))
      end

      def session_data
        @session_data ||= { "#{provider}_oauth_state" => generate_key }
      end

      def generate_key
        Digest::SHA1.hexdigest(rand(10**16).to_s + Time.now.to_f.to_s)
      end

      def trusted?
        state == stored_state
      end

      def authorized?
        !code.blank? && trusted?
      end

      def access_denied?
        error == 'access_denied'
      end

    end

  end
end

