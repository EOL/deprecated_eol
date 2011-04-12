module EOL
  module Feedable
    def feed(options = {})
      @feed_cache ||= EOL::Feed.find(self, options)
    end
    def reload(*args)
      @feed_cache = nil
      super args
    end
  end
end
