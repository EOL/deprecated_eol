require 'spec_helper'

describe FeedItemType do
  before(:all) do
    FeedItemType.delete_all
  end

  it "should create defaults" do
    FeedItemType.create_defaults
    FeedItemType.content_update.should_not be_nil
    FeedItemType.curator_activity.should_not be_nil
    FeedItemType.curator_comment.should_not be_nil
    FeedItemType.user_comment.should_not be_nil
  end
end
