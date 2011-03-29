module EOL
  module Feedable
    def feed
      @feed_cache ||= EOL::Feed.find(self)
    end
    def reload(*args)
      @feed_cache = nil
      super args
    end
  end
end
