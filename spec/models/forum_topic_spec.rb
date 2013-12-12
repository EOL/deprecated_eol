require File.dirname(__FILE__) + '/../spec_helper'

describe ForumTopic do

  before(:all) do
    load_foundation_cache
  end

  it 'should have a visible named scope' do
    ForumTopic.destroy_all
    3.times do
      ForumTopic.gen
    end
    3.times do
      ForumTopic.gen(deleted_at: Time.now)
    end
    ForumTopic.count.should == 6
    ForumTopic.visible.count.should == 3
  end

  it "should increment the topic count of its forum on create" do
    topic1 = ForumTopic.gen
    post1 = ForumPost.gen(forum_topic: topic1)
    topic1.forum.number_of_topics.should == 1
    topic2 = ForumTopic.gen(forum: topic1.forum)
    post2 = ForumPost.gen(forum_topic: topic2)
    topic2.forum.number_of_topics.should == 2
  end

  it "should increment the topic count of its forum on destroy" do
    topic1 = ForumTopic.gen
    post1 = ForumPost.gen(forum_topic: topic1)
    topic1.forum.number_of_topics.should == 1             # 1 topic
    topic2 = ForumTopic.gen(forum: topic1.forum)
    post2 = ForumPost.gen(forum_topic: topic2)         # 2 topics
    topic1.forum.number_of_topics.should == 2
    post3 = ForumPost.gen(forum_topic: topic2)         # .... still 2 topics
    topic1.forum.number_of_topics.should == 2
    topic1.update_attributes({ deleted_at: Time.now })
    topic1.forum.number_of_topics.should == 1             # back to 1
  end

end
