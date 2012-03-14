module EOL
  module OpenAuth
    # Shared attributes and methods for OAuth servers using OAuth 2 protocol.
    class Protocol2 < EOL::OpenAuth::Base

      attr_reader :code

      def initialize(provider, config, callback, code = nil)
        super(provider, config, callback)
        # TODO: Replace eval with some other solution - const_get doesn't seem to work for environment vars
        @client = OAuth2::Client.new(eval(config['key']), eval(config['secret']), config['params'].dup)
        @authorize_uri = client.auth_code.authorize_url((config['authorize_url_params'] || {}).merge(:redirect_uri => callback))
        @code = code
      end

      def access_token
        @access_token ||= client.auth_code.get_token(code, (config['access_token_params'] || {}).merge(:redirect_uri => callback))
      end

    end

  end
end

