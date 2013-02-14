require File.dirname(__FILE__) + '/../../spec_helper'

describe Forums::PostsController do

  before(:all) do
    load_foundation_cache
  end

  describe 'POST create' do
    it "must be logged in to create" do
      topic = ForumTopic.gen
      post :create, :topic_id => topic.id,
        :forum_post => {
          :forum_topic_id => topic.id,
          :subject => "post subject",
          :text => "post body" }
      response.header["Location"].should =~ /\/login/
    end

    it "logged in users can create" do
      session[:user_id] = User.gen(:admin => 1).id
      topic = ForumTopic.gen
      post :create, :topic_id => topic.id,
        :forum_post => {
          :forum_topic_id => topic.id,
          :subject => "post subject",
          :text => "post body" }
      response.header["Location"].should_not =~ /\/login/
    end
  end

  describe 'DELETE destroy' do
    it 'should redirect non-logged in users to login before deleting' do
      p = ForumPost.gen
      session[:user_id] = nil
      lambda { post :destroy, :id => p.id }.should_not raise_error(EOL::Exceptions::SecurityViolation)
      response.header["Location"].should =~ /\/login/
    end

    it 'should not allow unauthorized users to delete' do
      p = ForumPost.gen
      session[:user_id] = User.gen.id
      lambda { post :destroy, :id => p.id }.should raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should allow owners to delete posts' do
      p = ForumPost.gen
      session[:user_id] = p.user.id
      lambda { post :destroy, :id => p.id }.should_not raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should allow admins to delete posts' do
      p = ForumPost.gen
      session[:user_id] = User.gen(:admin => 1).id
      lambda { post :destroy, :id => p.id }.should_not raise_error(EOL::Exceptions::SecurityViolation)
    end
  end
end
