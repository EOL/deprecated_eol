module EOL
  # Wrapper for initializing Open Authentication instances for different providers
  module OpenAuth

    def self.config_file
      @config_file ||= YAML.load_file(Rails.root.join('config', 'oauth.yml'))
    end

    def self.init(provider, callback, options = { :code => nil,
                                                  :state => nil,
                                                  :stored_state => nil,
                                                  :error => nil,
                                                  :request_token_token => nil,
                                                  :request_token_secret => nil,
                                                  :oauth_verifier => nil,
                                                  :denied => nil })
      case provider
      when 'facebook'
        EOL::OpenAuth::Facebook.new(callback, options[:code], options[:state], options[:stored_state],
                                    options[:error])
      when 'google'
        EOL::OpenAuth::Google.new(callback, options[:code], options[:state], options[:stored_state],
                                  options[:error])
      when 'twitter'
        EOL::OpenAuth::Twitter.new(callback, options[:request_token_token], options[:request_token_secret],
                                   options[:oauth_verifier], options[:denied])
      when 'yahoo'
        EOL::OpenAuth::Yahoo.new(callback, options[:request_token_token], options[:request_token_secret],
                                 options[:oauth_verifier], options[:denied])
      end
    end

  end
end

