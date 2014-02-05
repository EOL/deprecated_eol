module EOL::LivesHere
  class Query
    attr_accessor :latitude, :longitude, :options

    def initialize(latitude, longitude, options = {})
      @latitude  = latitude
      @longitude = longitude
      @options   = options
    end

    def execute
      service.search(self)
    end

    def service
      EOL::LivesHere::Services.get(EOL::LivesHere.config.service)
    end
  end
end
