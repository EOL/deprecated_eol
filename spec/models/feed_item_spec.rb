require 'spec_helper'

describe FeedItem do

  before(:all) do
    @user = User.gen
  end

  it 'should be invalid without a feed relationship' do
    fi = FeedItem.create(:feed_type => 'User', :body => 'a')
    fi.valid?.should_not be_true
    fi = FeedItem.create(:feed_id => @user.id, :body => 'a')
    fi.valid?.should_not be_true
  end

  it 'should be invalid without a body' do
    fi = FeedItem.create(:feed_id => @user.id, :feed_type => 'User')
    fi.valid?.should_not be_true
  end

  it 'should be valid with a feed relationship and a body' do
    fi = FeedItem.create(:feed_id => @user.id, :feed_type => 'User', :body => 'a')
    fi.valid?.should be_true
  end

end
