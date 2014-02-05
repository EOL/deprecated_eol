require 'uri'

module EOL::LivesHere::Services
  class Mol < Base

    def initialize
    end

    def name
      # TODO i18n?
      'Map of Life'
    end

    def url(query)
      uri = URI.parse('http://api.mol.org/list')
      uri.query = URI.encode_www_form([
        ['lat', query.latitude],
        ['lon', query.longitude],
        ['radius', query.options[:radius] || EOL::LivesHere.config.mol[:radius]],
        ['api_key', EOL::LivesHere.config.mol[:api_key]]
      ]);
      uri.to_s
    end
  end
end

