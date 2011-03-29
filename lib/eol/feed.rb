module EOL
  class Feed

    include Enumerable

    def self.find(feed)
      Feed.new(feed)
    end

    def initialize(feed)
      @klass = feed.class.name
      @id    = feed.id
      @feed = FeedItem.find(:all, :conditions => ['feed_type = ? AND feed_id = ?', @klass, @id])
    end

    # This is the main method for actually adding a post to the feed.  Takes a body by default; other values optional.
    def post(body, options = {})
      values = {:feed_type => @klass, :feed_id => @id, :body => body}.merge(options)
      if item = FeedItem.create(values)
        @feed << item
      else
        raise "Unable to create a feed item"
      end
    end

    #
    # Basically, the rest of the functions here are simply implementing Enumerable.  You can probalbly skip reading these:
    #
    def [] which
      @feed[which]
    end

    # Don't use this unless you know what you're doing; use #post instead.
    def << item
      @feed << item
    end

    def count
      @feed.count
    end

    def length
      @feed.length
    end

    def blank?
      @feed.blank?
    end

    def each
      @feed.each {|fi| yield(fi) }
    end

    def empty?
      @feed.empty?
    end

    def first
      @feed.first
    end

    def last
      @feed.last
    end

    def nil?
      @feed.nil?
    end

  end
end
