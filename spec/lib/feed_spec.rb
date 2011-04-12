require File.dirname(__FILE__) + '/../spec_helper'

EOL::Feed # load the real one before we modify it, heh

module EOL
  class Feed
    def delete_all_entries
      @feed.each do |item|
        FeedItem.delete(item.id)
      end
      @feed = []
    end
  end
end

describe EOL::Feed do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching(:testy)
    @testy = EOL::TestInfo.load('testy')
    Capybara.reset_sessions!
    HierarchiesContent.delete_all
    @cp = ContentPartner.gen # It's a not-so-busy model we can test against...
    @dato = DataObject.gen
    @user = User.gen
    @watched_user = User.gen
    @user.watch_collection.add(@watched_user)
    @community = Community.gen
    @community.focus.add(@watched_user)
    @watched_user_post = "This is the feed item I added to the watched user"
    @watched_user.feed.post @watched_user_post
    @watched_user.watch_collection.add(@dato)
    @dato_feed_post = "This is an item I added to the dato"
    @dato.feed.post @dato_feed_post
  end

  before(:each) do
    @cp.feed.delete_all_entries
  end

  # NOTE - if this runs out of order, it will fail.  If that happens, you'll have to clear out the feed items yourself.
  it 'should be empty by default' do
    @cp.feed.should be_empty
  end

  it '<< should add a feed item' do
    fi = FeedItem.gen
    @cp.feed << fi
    @cp.feed.last.should == fi
  end

  it '#post should add a body do this item' do
    @cp.feed.post "Some body"
    @cp.feed.last.body.should == "Some body"
    @cp.feed.last.feed.should == @cp
  end

  it 'should list all feed items' do
    fi1 = FeedItem.gen
    fi2 = FeedItem.gen
    fi3 = FeedItem.gen
    fi4 = FeedItem.gen
    @cp.feed << fi1
    @cp.feed << fi2
    @cp.feed << fi3
    @cp.feed << fi4
    @cp.feed.items.should == [fi1, fi2, fi3, fi4] # Note the [0..-1] avoids using the Feed class, returns an array.
  end

  it 'should find feed items from user watch lists (one level deep)' do
    @user.feed.map {|i| i.body }.should include(@watched_user_post)
  end

  it 'should NOT follow children from user watch lists' do
    @user.feed.map {|i| i.body }.should_not include(@dato_feed_post)
  end

  it 'should find feed items from community focus lists (one level deep)' do
    @community.feed.map {|i| i.body }.should include(@watched_user_post)
  end

  it 'should NOT follow children from community focus lists' do
    @community.feed.map {|i| i.body }.should_not include(@dato_feed_post)
  end

end
