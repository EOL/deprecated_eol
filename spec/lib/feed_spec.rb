require File.dirname(__FILE__) + '/../spec_helper'

describe EOL::Feed do

  describe '#feed' do

    it 'should be empty by default' do
      cp = ContentPartner.gen # I'm not sure this is wise, but it's a not-so-busy model we can test against...
      cp.feed.should be_empty
    end

    it '<< should add a feed item' do
      cp = ContentPartner.gen # I'm not sure this is wise, but it's a not-so-busy model we can test against...
      fi = FeedItem.gen
      cp.feed << fi
      cp.feed.last.should == fi
    end

    it '#post should add a body do this item' do
      cp = ContentPartner.gen
      cp.feed.post "Some body"
      cp.feed.last.body.should == "Some body"
      cp.feed.last.feed.should == cp
    end

    it 'should list all feed items' do
      cp = ContentPartner.gen # I'm not sure this is wise, but it's a not-so-busy model we can test against...
      fi1 = FeedItem.gen
      fi2 = FeedItem.gen
      fi3 = FeedItem.gen
      fi4 = FeedItem.gen
      cp.feed << fi1
      cp.feed << fi2
      cp.feed << fi3
      cp.feed << fi4
      cp.feed[0..3].should == [fi1, fi2, fi3, fi4]
    end

  end

end
