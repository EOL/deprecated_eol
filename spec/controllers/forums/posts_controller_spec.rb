require File.dirname(__FILE__) + '/../../spec_helper'

describe Forums::PostsController do

  before(:all) do
    load_foundation_cache
  end

  describe 'POST create' do
    it "must be logged in to create" do
      post :create, :forum_post => {
        :forum_topic_id => ForumTopic.gen.id,
        :subject => "post subject",
        :text => "post body" }
      response.header["Location"].should =~ /\/login/
    end

    it "logged in users can create" do
      session[:user_id] = User.gen(:admin => 1).id
      post :create, :forum_post => {
        :forum_topic_id => ForumTopic.gen.id,
        :subject => "post subject",
        :text => "post body" }
      response.header["Location"].should =~ /\/login/
    end
  end

  describe 'DELETE destroy' do
    it 'should not allow unauthorized deleting' do
      p = ForumPost.gen
      session[:user_id] = nil
      lambda { post :destroy, :id => p.id }.should raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should allow owners to delete posts' do
      p = ForumPost.gen
      session[:user_id] = post.user.id
      lambda { post :destroy, :id => p.id }.should_not raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should allow admins to delete posts' do
      p = ForumPost.gen
      session[:user_id] = User.gen(:admin => 1).id
      lambda { post :destroy, :id => p.id }.should_not raise_error(EOL::Exceptions::SecurityViolation)
    end
  end
end
