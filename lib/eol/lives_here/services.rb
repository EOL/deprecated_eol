module EOL::LivesHere
  module Services

    extend self

    def all
      [:mol]
    end

    def get(handle)
      @services = {} unless defined?(@services)
      @services[handle] = spawn(handle) unless @services.include?(handle)
      @services[handle]
    end

    private

    def spawn(handle)
      if all.include?(handle)
        EOL::LivesHere::Services.const_get(handle.to_s.classify).new
      else
        raise "No matching service for #{handle}"
      end
    end

  end

end
