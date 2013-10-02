require File.dirname(__FILE__) + '/../spec_helper'

describe ForumsController do

  before(:all) do
    load_foundation_cache
  end

  describe 'POST create' do
    it "When not logged in, users cannot update the description" do
      post :create, :forum => {
        :forum_category_id => ForumCategory.gen.id,
        :name => "Sdasdf",
        :description => "4fasfdasd" }
      response.header["Location"].should =~ /\/login/
    end
  end

  describe 'DELETE destroy' do
    it 'should not allow unauthorized deleting' do
      forum = Forum.gen
      session[:user_id] = nil
      lambda { post :destroy, :id => forum.id }.should raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should allow admins to delete forums' do
      forum = Forum.gen
      session[:user_id] = User.gen(:admin => 1).id
      lambda { post :destroy, :id => forum.id }.should_not raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should not allow unauthorized moving' do
      forum = Forum.gen
      session[:user_id] = nil
      lambda { post :move_up, :id => forum.id }.should raise_error(EOL::Exceptions::SecurityViolation)
      lambda { post :move_down, :id => forum.id }.should raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should allow admins to move forums' do
      forum = Forum.gen
      session[:user_id] = User.gen(:admin => 1).id
      lambda { post :move_up, :id => forum.id }.should_not raise_error(EOL::Exceptions::SecurityViolation)
      lambda { post :move_down, :id => forum.id }.should_not raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should not allow unauthorized creating' do
      session[:user_id] = nil
      get :create
      response.header["Location"].should =~ /\/login/
    end

    it 'should allow admins to create forums' do
      session[:user_id] = User.gen(:admin => 1).id
      get :create
      response.header["Location"].should_not =~ /\/login/
    end
  end
end
