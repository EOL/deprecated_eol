require File.dirname(__FILE__) + '/../../spec_helper'

describe Forums::CategoriesController do

  before(:all) do
    load_foundation_cache
    @normal_user = User.gen
    @admin = User.gen(:admin => true)
  end

  describe 'POST create' do
    it "must be an admin to create" do
      session[:user_id] = nil
      lambda { post :create, :forum_category => { :title => 'New category' }
        }.should raise_error(EOL::Exceptions::SecurityViolation)
    end

    it "must be an admin to create" do
      session[:user_id] = @normal_user.id
      lambda { post :create, :forum_category => { :title => 'New category' }
        }.should raise_error(EOL::Exceptions::SecurityViolation)
    end

    it "admins can create" do
      session[:user_id] = @admin.id
      lambda { post :create, :forum_category => { :title => 'New category' }
        }.should_not raise_error(EOL::Exceptions::SecurityViolation)
    end
  end

  describe 'POST move_up, move_down' do
    before(:all) do
      5.times { ForumCategory.gen }
    end
    before(:each) do
      session[:user_id] = @admin.id
    end

    it "should move categories up" do
      last_category = ForumCategory.order(:view_order).last
      original_view_order = last_category.view_order
      post :move_up, :id => last_category.id
      last_category.reload.view_order.should == original_view_order - 1
      ForumCategory.find_by_view_order(original_view_order).should_not be_nil
      ForumCategory.find_by_view_order(original_view_order).should_not == last_category
    end

    it "should not move first category up" do
      post :move_up, :id => ForumCategory.order(:view_order).first.id
      flash[:error].should == I18n.t('forums.categories.move_failed')
    end

    it "should move categories down" do
      first_category = ForumCategory.order(:view_order).first
      original_view_order = first_category.view_order
      post :move_down, :id => first_category.id
      first_category.reload.view_order.should == original_view_order + 1
      ForumCategory.find_by_view_order(original_view_order).should_not be_nil
      ForumCategory.find_by_view_order(original_view_order).should_not == first_category
    end

    it "should not move last category down" do
      post :move_down, :id => ForumCategory.order(:view_order).last.id
      flash[:error].should == I18n.t('forums.categories.move_failed')
    end
  end

  describe 'PUT update' do
    before(:each) do
      session[:user_id] = @admin.id
    end
    it "should update categories" do
      c = ForumCategory.gen(:title => 'Test title', :description => 'Test description')
      put :update, :id => c.id, :forum_category => {
        :title => "New title",
        :description => "New description" }
      c.reload
      c.title.should == "New title"
      c.description.should == "New description"
    end
  end

  describe 'DELETE destroy' do
    it 'must be admin to delete' do
      c = ForumCategory.gen
      session[:user_id] = nil
      lambda { post :destroy, :id => c.id }.should raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'must be admin to delete' do
      c = ForumCategory.gen
      session[:user_id] = @normal_user.id
      lambda { post :destroy, :id => c.id }.should raise_error(EOL::Exceptions::SecurityViolation)
    end

    it 'should allow admins to delete posts' do
      c = ForumCategory.gen
      session[:user_id] = @admin.id
      lambda { post :destroy, :id => c.id }.should_not raise_error(EOL::Exceptions::SecurityViolation)
    end
  end
end
