module EOL

  class Server

    def self.ip_address
      @ip ||= Socket.ip_address_list.detect { |intf| intf.ipv4_private? }.try(:ip_address)
    end

    def self.domain
      @domain ||= Rails.configuration.site_domain || $SITE_DOMAIN_OR_IP
    end

  end
  
end
