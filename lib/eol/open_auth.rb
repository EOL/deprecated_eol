module EOL
  # Wrapper for initializing Open Authentication instances for different providers
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
        EOL::OpenAuth::Facebook.new(callback, options[:code])
      when 'google'
        EOL::OpenAuth::Google.new(callback, options[:code])
      when 'twitter'
        EOL::OpenAuth::Twitter.new(callback, options[:request_token_token], options[:request_token_secret], options[:oauth_verifier])
      when 'yahoo'
        EOL::OpenAuth::Yahoo.new(callback, options[:request_token_token], options[:request_token_secret], options[:oauth_verifier])
      end
    end

  end
end

