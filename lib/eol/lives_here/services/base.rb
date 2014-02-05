require 'open-uri'
require 'json'

module EOL::LivesHere::Services

  class Base

    def name
      fail
    end

    def handle
      self.class.to_s.underscore.to_sym
    end

    def search(query)
      result_klass.new(fetch(query))
    end

    def url(query)
      fail
    end

    def fetch(query)
      begin
        return JSON.load(open(url(query)), nil, { symbolize_names: true })
      rescue OpenURI::HTTPError => e
        logger.error e.message
      end
    end

    def result_klass
      EOL::LivesHere::Result.const_get(self.class.to_s.split(":").last)
    end

  end
end
