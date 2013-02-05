require File.dirname(__FILE__) + '/../spec_helper'

describe ForumTopic do

  before(:all) do
    load_foundation_cache
  end

  it "should increment the topic count of its forum" do
    topic1 = ForumTopic.gen
    topic1.forum.number_of_topics.should == 1
    topic2 = ForumTopic.gen(:forum => topic1.forum)
    topic2.forum.number_of_topics.should == 2
  end

end
