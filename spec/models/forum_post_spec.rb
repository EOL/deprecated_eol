require File.dirname(__FILE__) + '/../spec_helper'

describe ForumPost do

  before(:all) do
    load_foundation_cache
  end

  it 'should have a visible named scope' do
    ForumPost.destroy_all
    3.times do
      ForumPost.gen
    end
    3.times do
      ForumPost.gen(:deleted_at => Time.now)
    end
    ForumPost.count.should == 6
    ForumPost.visible.count.should == 3
  end

  it "should set the first post on its topic when there isn't one" do
    post1 = ForumPost.gen
    post1.forum_topic.first_post.should == post1
    post2 = ForumPost.gen(:forum_topic => post1.forum_topic)
    post2.forum_topic.first_post.should == post1
  end

  it "should set the last post on its topic on create" do
    post1 = ForumPost.gen
    post1.forum_topic.last_post.should == post1
    post2 = ForumPost.gen(:forum_topic => post1.forum_topic)
    post1.forum_topic.reload.last_post.should == post2
  end

  it "should properly set the last post on its topic on delete" do
    post1 = ForumPost.gen
    post1.forum_topic.last_post.should == post1
    post2 = ForumPost.gen(:forum_topic => post1.forum_topic)
    post1.forum_topic.reload.last_post.should == post2
    post2.update_attributes({ :deleted_at => Time.now })
    post1.forum_topic.reload.last_post.should == post1
  end

  it "should increment the post count of its topic on create" do
    post1 = ForumPost.gen
    post1.forum_topic.number_of_posts.should == 1
    post2 = ForumPost.gen(:forum_topic => post1.forum_topic)
    post1.forum_topic.reload.number_of_posts.should == 2
  end

  it "should properly decrease the post count of its topic on delete" do
    post1 = ForumPost.gen
    post1.forum_topic.number_of_posts.should == 1
    post2 = ForumPost.gen(:forum_topic => post1.forum_topic)
    post1.forum_topic.reload.number_of_posts.should == 2
    post2.update_attributes({ :deleted_at => Time.now })
    post1.forum_topic.reload.number_of_posts.should == 1
  end

  it "should increment its edit count" do
    post = ForumPost.gen
    post.edit_count.should == 0
    post.text = "something different"
    post.save
    post.edit_count.should == 1
  end

  it "should increment its authors post count on create" do
    post = ForumPost.gen
    post.user.number_of_forum_posts.should == 1
    5.times do
      ForumPost.gen(:user => post.user)
    end
    post.user.reload.number_of_forum_posts.should == 6
  end

  it "should decrease its authors post count on delete" do
    post = ForumPost.gen
    post.user.number_of_forum_posts.should == 1
    5.times do
      ForumPost.gen(:user => post.user)
    end
    post.user.reload.number_of_forum_posts.should == 6
    ForumPost.last.update_attributes({ :deleted_at => Time.now })
    post.user.reload.number_of_forum_posts.should == 5
  end

  it "should update its topics title when its the first post" do
    post1 = ForumPost.gen
    post2 = ForumPost.gen(:forum_topic => post1.forum_topic)
    post1.save
    post1.topic_starter?.should == true
    post1.forum_topic.reload.title.should == post1.subject
    # update the first post's title
    post1.update_attributes({ :subject => 'New subject' })
    post1.forum_topic.reload.title.should == 'New subject'
    # updating the second post's title
    post2.update_attributes({ :subject => 'Second Post New subject' })
    post1.forum_topic.reload.title.should == 'New subject'
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
    expect {
      post = ForumPost.gen(:subject => "can't be nil", :forum_topic => post.forum_topic)
    }.not_to raise_error
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
    expect { post = ForumPost.gen(:text => "Text") }.not_to raise_error
    expect { post = ForumPost.gen(:text => "\nText") }.not_to raise_error
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
