require File.dirname(__FILE__) + '/../../spec_helper'

describe Admins::NewsItemsController do

  before(:all) do
    unless @admin = User.find_by_username('admins_controller_specs')
      truncate_all_tables
      load_foundation_cache
      @admin = User.gen(:username => 'admins_controllers_specs', :password => "password", :admin => true)
    end
    @non_admin = User.find_by_admin(false)
  end

  describe 'GET index' do
    it 'should only allow access to EOL administrators' do
      get :index
      response.redirected_to.should == login_url
      expect{ get :index, nil, { :user => @non_admin, :user_id => @non_admin.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should instantiate page_title' do
      get :index, nil, { :user => @admin, :user_id => @admin.id }
      assigns[:page_title].should == I18n.t(:admin_news_items_page_title)
    end
    it 'should instantiate news items ordered by updated_at in descending order' do
      news_items = NewsItem.paginate(:order=>'updated_at desc', :page => '1', :per_page => 25)
      get :index, nil, { :user => @admin, :user_id => @admin.id }
      assigns[:news_items].should == news_items
      response.redirected_to.should be_nil
      response.rendered[:template].should == "admins/news_items/index.html.haml"
    end
  end

  describe 'GET new' do
    it 'should only allow access to EOL administrators' do
      get :new
      response.redirected_to.should == login_url
      expect{ get :index, nil, { :user => @non_admin, :user_id => @non_admin.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should instantiate page_title, page_subheader and languages' do
      get :new, nil, { :user => @admin, :user_id => @admin.id }
      assigns[:page_title].should == I18n.t(:admin_news_items_page_title)
      assigns[:page_subheader].should == I18n.t(:admin_news_item_new_header)
      assigns[:languages].should_not be_blank
    end
    it 'should instantiate news item' do
      get :new, nil, { :user => @admin, :user_id => @admin.id }
      assigns[:news_item].class.should == NewsItem
      assigns[:news_item].active.should be_true
      response.redirected_to.should be_nil
      response.rendered[:template].should == "admins/news_items/new.html.haml"
    end
  end

  describe 'POST create' do
    before :all do
      @new_news_item_params = { 
        :news_item => { :page_name => "test_news", :active => true,
          "activated_on(3i)" => "13", "activated_on(2i)" => "7", "activated_on(1i)" => "2012", "activated_on(4i)" => "20",
          "activated_on(5i)" => "16", "display_date(3i)" => "14", "display_date(2i)" => "7", "display_date(1i)" => "2012",
          "display_date(4i)" => "20", "display_date(5i)" => "20" },
        :translated_news_item => { :title => "Test News", :body => "Test News Item",
                                   :language_id => Language.english.id, :active_translation => true } }
    end
    it 'should only allow access to EOL administrators' do
      post :create
      response.redirected_to.should == login_url
      expect{ get :index, nil, { :user => @non_admin, :user_id => @non_admin.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should create a news item' do
      post :create, @new_news_item_params, { :user => @admin, :user_id => @admin.id }
      assigns[:news_item].page_name.should == "test_news"
      assigns[:news_item].active.should be_true
      assigns[:news_item].activated_on.to_s.should == "2012-07-13 20:16:00 UTC"
      assigns[:news_item].display_date.to_s.should == "2012-07-14 20:20:00 UTC"
      assigns[:translated_news_item].title.should == "Test News"
      assigns[:translated_news_item].body.should == "Test News Item"
      assigns[:translated_news_item].language_id.should == Language.english.id
      assigns[:translated_news_item].active_translation.should be_true
    end
  end

  describe 'GET edit' do
    before :all do
      @news_item_to_edit = NewsItem.gen(:page_name => "test_editing_news", :active => true, :user => @admin)
      @edit_news_item_params = { :id => @news_item_to_edit.id }
    end
    it 'should only allow access to EOL administrators' do
      get :edit
      response.redirected_to.should == login_url
      expect{ get :index, nil, { :user => @non_admin, :user_id => @non_admin.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should instantiate page_title, page_subheader and page_name' do
      get :edit, @edit_news_item_params, { :user => @admin, :user_id => @admin.id }
      assigns[:page_title].should == I18n.t(:admin_news_items_page_title)
      assigns[:page_subheader].should == I18n.t(:admin_news_item_edit_header, :page_name => "test_editing_news")
    end
    it 'should edit a news item' do
      get :edit, @edit_news_item_params, { :user => @admin, :user_id => @admin.id }
      assigns[:news_item].class.should == NewsItem
      assigns[:news_item].id.should == @news_item_to_edit.id
      assigns[:news_item].page_name.should == "test_editing_news"
      assigns[:news_item].last_update_user_id.should == @admin.id
      assigns[:news_item].active.should be_true
    end
  end

  describe 'PUT update' do
    before :all do
      @news_item_to_update = NewsItem.gen(:page_name => "test_updating_news", :active => true, :user => @admin)
      @update_news_item_params = { :id => @news_item_to_update.id,
        :news_item => { :page_name => "test_news", :active => true,
          "activated_on(3i)" => "13", "activated_on(2i)" => "7", "activated_on(1i)" => "2013", "activated_on(4i)" => "20",
          "activated_on(5i)" => "16", "display_date(3i)" => "14", "display_date(2i)" => "7", "display_date(1i)" => "2013",
          "display_date(4i)" => "20", "display_date(5i)" => "20" } }
    end
    it 'should only allow access to EOL administrators' do
      put :update
      response.redirected_to.should == login_url
      expect{ get :index, nil, { :user => @non_admin, :user_id => @non_admin.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should update a news item' do
      page_name = @update_news_item_params[:news_item][:page_name]
      put :update, @update_news_item_params, { :user => @admin, :user_id => @admin.id }
      assigns[:news_item].class.should == NewsItem
      flash[:notice].should == I18n.t(:admin_news_item_update_successful_notice, :page_name => page_name,
                                      :anchor => page_name.gsub(' ', '_').downcase)
      response.redirected_to.should == admin_news_items_path(:anchor => page_name.gsub(' ', '_').downcase)
    end
  end

  describe 'DELETE destroy' do
    before :all do
      @news_item_to_delete = NewsItem.gen(:page_name => "test_deleting_news", :active => true, :user => @admin)
      @delete_news_item_params = { :id => @news_item_to_delete.id }
    end
    it 'should only allow access to EOL administrators' do
      delete :destroy
      response.redirected_to.should == login_url
      expect{ get :index, nil, { :user => @non_admin, :user_id => @non_admin.id } }.should raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should delete a news item' do
      delete :destroy, @delete_news_item_params, { :user => @admin, :user_id => @admin.id }
      flash[:notice].should == I18n.t(:admin_news_item_delete_successful_notice, :page_name => "test_deleting_news")
      response.redirected_to[:action].should == "index"
    end
  end

end