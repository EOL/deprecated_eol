require File.dirname(__FILE__) + '/../spec_helper'

describe EOL::Feed do

  describe '#feed' do

    before(:all) do
      @cp = ContentPartner.gen # I'm not sure this is wise, but it's a not-so-busy model we can test against...
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
      @cp.feed[-4..-1].should == [fi1, fi2, fi3, fi4]
    end

    it 'should propagate feed items to user watch lists' do
      user = User.gen
      watched_user = User.gen
      user.watch_collection.add(watched_user)
      watched_user.feed.post "This is the feed item I added"
      user.feed.last.body.should =~ /This is the feed item I added/
    end

  end

end
