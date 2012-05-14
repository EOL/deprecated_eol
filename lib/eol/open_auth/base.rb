module EOL
  module OpenAuth
    # Base class for Open Authentications shared attributes and methods for use with both OAuth 1.0 and OAuth 2.0 protocols.
    class Base

      attr_accessor :config, :callback, :client, :provider, :taken
      attr_writer :authorize_uri, :access_token, :basic_info, :user_attributes,
                  :authentication_attributes, :guid, :session_data

      def initialize(provider, config, callback)
        @provider = provider
        @config = config
        @callback = callback
      end

      def guid
        @guid ||= authentication_attributes[:guid]
      end

      def session_data
        @session ||= nil
      end

      def open_authentication
        @open_authentication ||= OpenAuthentication.find_by_provider_and_guid(provider, guid)
      end

      def have_attributes?
        !user_attributes.nil? && !authentication_attributes.nil? &&
        !authentication_attributes[:guid].blank? && !authentication_attributes[:provider].blank?
      end

      def is_connected?
        !open_authentication.nil?
      end

      def get_data(uri)
        response = access_token.get(uri)
        raise EOL::Exceptions::OpenAuthBadResponse,
          "Bad response from #{uri}" unless response_ok?(response)
        JSON.parse(response.body)
      end

      def response_ok?(response)
        response.respond_to?(:code) && response.code == "200" ||
        response.respond_to?(:status) && response.status == 200
      end

    end

  end
end

