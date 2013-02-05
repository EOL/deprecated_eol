require File.dirname(__FILE__) + '/../spec_helper'

describe ForumPost do

  before(:all) do
    load_foundation_cache
  end

  it "should set the first post on its topic when there isn't one" do
    post1 = ForumPost.gen
    post1.forum_topic.first_post.should == post1
    post2 = ForumPost.gen(:forum_topic => post1.forum_topic)
    post2.forum_topic.first_post.should == post1
  end

  it "should set the last post on its topic" do
    post1 = ForumPost.gen
    post1.forum_topic.last_post.should == post1
    post2 = ForumPost.gen(:forum_topic => post1.forum_topic)
    post2.forum_topic.last_post.should == post2
  end

  it "should increment the post count of its topic" do
    post1 = ForumPost.gen
    post1.forum_topic.number_of_posts.should == 1
    post2 = ForumPost.gen(:forum_topic => post1.forum_topic)
    post2.forum_topic.number_of_posts.should == 2
  end

  it "should increment its edit count" do
    post = ForumPost.gen
    post.edit_count.should == 0
    post.text = "something different"
    post.save
    post.edit_count.should == 1
  end

  it "should create a reasonable reply to subject" do
    post = ForumPost.gen(:subject => "Its a post")
    post.reply_to_subject.should == "Re: Its a post"
    post = ForumPost.gen(:subject => "Re: Its a post")
    post.reply_to_subject.should == "Re: Its a post"
    post = ForumPost.gen(:subject => "     Re: Its a post")
    post.reply_to_subject.should == "Re: Its a post"
  end

  it "should validate subjects on initial posts" do
    lambda { post = ForumPost.gen(:subject => nil) }.should raise_error(ActiveRecord::RecordInvalid)

    post = ForumPost.gen()
    lambda {
      post = ForumPost.gen(:subject => nil, :forum_topic => post.forum_topic)
    }.should_not raise_error(ActiveRecord::RecordInvalid)
  end

  it "should validate whitespace in text" do
    lambda { post = ForumPost.gen(:text => nil) }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = ForumPost.gen(:text => "") }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = ForumPost.gen(:text => " ") }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = ForumPost.gen(:text => "    ") }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = ForumPost.gen(:text => "  \n &nbsp;&nbsp;  \t   <p> \n\n</P>") }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = ForumPost.gen(:text => "\n") }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = ForumPost.gen(:text => "\r") }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = ForumPost.gen(:text => "<p></p>") }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = ForumPost.gen(:text => "<P></P>") }.should raise_error(ActiveRecord::RecordInvalid)
    lambda { post = ForumPost.gen(:text => "Text") }.should_not raise_error(ActiveRecord::RecordInvalid)
    lambda { post = ForumPost.gen(:text => "\nText") }.should_not raise_error(ActiveRecord::RecordInvalid)
  end

  it 'should be able to be updated by owners and admins' do
    post = ForumPost.gen
    post.user.can_update?(post).should == true
    User.gen(:admin => 1).can_update?(post).should == true
    User.gen.can_update?(post).should == false
  end

  it 'should be able to be updated by topic creators' do
    post1 = ForumPost.gen
    post2 = ForumPost.gen(:forum_topic => post1.forum_topic)
    post1.user.can_update?(post2).should == true
    post2.user.can_update?(post1).should == false
    User.gen.can_update?(post1).should == false
    User.gen.can_update?(post2).should == false
    User.gen(:admin => 1).can_update?(post1).should == true
    User.gen(:admin => 1).can_update?(post2).should == true
  end

  it 'should be able to be deleted by owners and admins' do
    post = ForumPost.gen
    post.user.can_delete?(post).should == true
    User.gen(:admin => 1).can_delete?(post).should == true
    User.gen.can_delete?(post).should == false
  end
end
