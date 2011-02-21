module EOL
  module Feedable
    def feed
      @feed_cache ||= EOL::Feed.find(self)
    end
  end
end
