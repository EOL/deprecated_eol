module EOL

  class Server

    # TODO: Bah! need to deduplicate this with lib/eol_web_service.rb
    def self.ip_address
      return ENV["LOCAL_IP"] if ENV["LOCAL_IP"]
      @ip ||= Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.try(:ip_address)
    end

    def self.domain
      @domain ||= Rails.configuration.site_domain || $SITE_DOMAIN_OR_IP
    end

  end
  
end
