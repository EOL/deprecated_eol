module EOL
  class Feed

    include Enumerable

    def self.find(feed, options = {})
      Feed.new(feed, options)
    end

    def initialize(source, options = {})
      @source = source
      @klass  = source.class.name
      @id     = source.id
      @feed   = FeedItem.find(:all, :conditions => ['feed_type = ? AND feed_id = ?', @klass, @id])
      # TODO - digest these
      if options[:follow_children].nil? || options[:follow_children]
        include_the_users_watch_collection if this_is_a_user_feed?
        include_the_community_focus_collection if this_is_a_community_feed?
      end
      # TODO - recurse over hierarchies...
    end

    # This is the main method for actually adding a post to the feed.  Takes a body by default; other values optional.
    def post(body, options = {})
      values = {:feed_item_type_id => FeedItemType.user_comment.id, :feed_type => @klass, :feed_id => @id,
        :body => body}.merge(options)
      # Make this a curator comment if it should be one (and the type wasn't already specified):
      if @source.respond_to?(:is_curatable_by?) && options[:user_id] && !options[:feed_item_type_id]
        values[:feed_item_type_id] = FeedItemType.curator_comment.id if @source.is_curatable_by? User.find(options[:user_id])
      end
      if item = FeedItem.create(values)
        @feed << item
      else
        raise "Unable to create a feed item"
      end
    end

    #
    # Basically, the rest of the functions here are simply implementing Enumerable.  You can probalbly skip reading these,
    # but start reading again at the "private" keyword--there are plenty of methods there that you may want to know about.
    #
    def [] which
      @feed[which]
    end

    # Don't use this unless you know what you're doing; use #post instead.
    def << item
      @feed << item
    end

    def +(other)
      if other.is_a? Array
        @feed += other
      else # assume it's a Feed
        @feed += other.items
      end
    end

    def items
      @feed
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

  private

    def this_is_a_community_feed?
      @klass == 'Community'
    end

    def this_is_a_user_feed?
      @klass == 'User'
    end

    def include_the_community_focus_collection
      include_followed_items(:focus)
    end

    def include_the_users_watch_collection
      include_followed_items(:watch_collection)
    end

    def include_followed_items(type)
      @source.send(type).collection_items.each do |item|
        @feed += item.object.feed(:follow_children => false).items if item.object.respond_to?(:feed)
      end
    end

  end
end
