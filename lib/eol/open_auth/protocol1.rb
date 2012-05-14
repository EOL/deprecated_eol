module EOL
  module OpenAuth
    # Shared attributes and methods for OAuth service providers using OAuth 1 protocol.
    class Protocol1 < EOL::OpenAuth::Base

      attr_accessor :request_token, :verifier, :denied

      def initialize(provider, config, callback, request_token_token = nil, request_token_secret = nil,
                     verifier = nil, denied = nil)
        super(provider, config, callback)
        # TODO: Replace eval with some other solution - const_get doesn't seem to work for environment vars
        @client = OAuth::Consumer.new(eval(config['key']), eval(config['secret']), config['params'].dup)
        @verifier = verifier
        @denied = denied
        if request_token_token && request_token_secret
          @request_token = OAuth::RequestToken.new(client, request_token_token, request_token_secret)
        else
          @request_token = client.get_request_token(:oauth_callback => callback)
        end
      end

      def authorize_uri
        @authorize_uri = request_token.authorize_url
      end

      def session_data
        @session_data ||= { "#{provider}_request_token_token" => request_token.token,
                            "#{provider}_request_token_secret" => request_token.secret }
      end

      def access_token
        @access_token ||= request_token.get_access_token(:oauth_verifier => verifier)
      end

      def authorized?
        !verifier.blank?
      end

      # NOTE: Yahoo! doesn't let users cancel authorization, so this doesn't apply.
      def access_denied?
        !denied.nil?
      end

    end

  end
end

