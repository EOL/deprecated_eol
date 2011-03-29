require 'spec_helper'

describe FeedItem do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    @tc = build_taxon_concept(:images => [{}])
    @image = @tc.images.first
    @curator = User.find(@tc.curators.last.id) # Weird syntax because @tc.curators ONLY has ids; no other attributes attached.
    @non_curator = User.gen
  end

  it 'should be invalid without a feed relationship' do
    fi = FeedItem.create(:feed_type => 'User', :body => 'a')
    fi.valid?.should_not be_true
    fi = FeedItem.create(:feed_id => @non_curator.id, :body => 'a')
    fi.valid?.should_not be_true
  end

  it 'should be invalid without a body' do
    fi = FeedItem.create(:feed_id => @non_curator.id, :feed_type => 'User')
    fi.valid?.should_not be_true
  end

  it 'should be valid with a feed relationship and a body' do
    fi = FeedItem.create(:feed_id => @non_curator.id, :feed_type => 'User', :body => 'a')
    fi.valid?.should be_true
  end

  it 'should create a Curator Comment if a curator comments on the taxon' do
    item = FeedItem.new_for(:feed => @tc, :user => @curator)
    item.feed_item_type.should == FeedItemType.curator_comment
  end

  it 'should create a User Comment if a user comments on the taxon' do
    item = FeedItem.new_for(:feed => @tc, :user => @non_curator)
    item.feed_item_type.should == FeedItemType.user_comment
  end

end
