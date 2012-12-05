require File.dirname(__FILE__) + '/../../spec_helper'

describe Admins::TranslatedNewsItemsController do

  before(:all) do
    unless @admin = User.find_by_username('admins_controller_specs')
      truncate_all_tables
      load_foundation_cache
      @admin = User.gen(:username => 'admins_controllers_specs', :password => "password", :admin => true)
    end
    @non_admin = User.find_by_admin(false)
    @news_item = NewsItem.gen(:page_name => "test_translated_news_item", :active => true, :user => @admin)
  end

  describe 'GET new' do
    before :all do
      @new_translated_news_item_params = { :news_item_id => @news_item.id }
    end
    it 'should only allow access to EOL administrators' do
      get :new
      response.should redirect_to(login_url)
      expect{ get :new, { :id => @news_item.id }, { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should instantiate page_title, page_subheader and languages' do
      get :new, @new_translated_news_item_params, { :user => @admin, :user_id => @admin.id }
      assigns[:page_title].should == I18n.t(:admin_news_items_page_title)
      assigns[:page_subheader].should == I18n.t(:admin_translated_news_item_new_subheader, :page_name => @news_item.page_name)
      assigns[:languages].should_not be_blank
    end
    it 'should instantiate translated news item' do
      get :new, @new_translated_news_item_params, { :user => @admin, :user_id => @admin.id }
      languages = assigns[:languages]
      assigns[:news_item].class.should == NewsItem
      assigns[:translated_news_item].class.should == TranslatedNewsItem
      assigns[:translated_news_item].language_id.should == languages.first.id
      assigns[:translated_news_item].active_translation.should be_true
      response.code.should eq('200')
    end
  end

  describe 'POST create' do
    before :all do
      @new_translated_news_item_params = { :news_item_id => @news_item.id,
        :translated_news_item => { :title => "Test Translated News", :body => "Test Translated News Item Body",
                                   :language_id => Language.english.id, :active_translation => true } }
    end
    before(:each) do
      TranslatedNewsItem.delete_all(:news_item_id => @news_item.id)
    end
    it 'should only allow access to EOL administrators' do
      post :create
      response.should redirect_to(login_url)
      expect{ get :new, { :id => @news_item.id }, { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should create a translated news item' do
      post :create, @new_translated_news_item_params, { :user => @admin, :user_id => @admin.id }
      assigns[:news_item].class.should == NewsItem
      assigns[:news_item].last_update_user_id == @admin.id
      assigns[:translated_news_item].title.should == "Test Translated News"
      assigns[:translated_news_item].body.should == "Test Translated News Item Body"
      assigns[:translated_news_item].language_id.should == Language.english.id
      assigns[:translated_news_item].active_translation.should be_true
      flash[:notice].should == I18n.t(:admin_translated_news_item_create_successful_notice,
                              :page_name => @news_item.page_name,
                              :anchor => @news_item.page_name.gsub(' ', '_').downcase)
      response.should redirect_to(news_items_path(:anchor => @news_item.page_name.gsub(' ', '_').downcase))
    end
  end

  describe 'GET edit' do
    before :all do
      TranslatedNewsItem.delete_all(:news_item_id => @news_item.id)
      @translated_news_item_to_edit = TranslatedNewsItem.gen(:news_item_id => @news_item.id,
                                                             :title => "Test Translated News",
                                                             :language => Language.english,
                                                             :body => "Test Translated News Item Body",
                                                             :active_translation => true)
      @edit_translated_news_item_params = { :news_item_id => @news_item.id, :id => @translated_news_item_to_edit.id }
    end
    it 'should only allow access to EOL administrators' do
      get :edit
      response.should redirect_to(login_url)
      expect{ get :edit, { :id => @news_item.id }, { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should instantiate page_title, page_subheader and page_name' do
      get :edit, @edit_translated_news_item_params, { :user => @admin, :user_id => @admin.id }
      assigns[:page_title].should == I18n.t(:admin_news_items_page_title)
      assigns[:page_subheader].should == I18n.t(:admin_translated_news_item_edit_subheader, :page_name => @news_item.page_name,
                                                :language => @translated_news_item_to_edit.language.label.downcase)
    end
    it 'should edit a translated news item' do
      get :edit, @edit_translated_news_item_params, { :user => @admin, :user_id => @admin.id }
      assigns[:news_item].class.should == NewsItem
      assigns[:translated_news_item].class.should == TranslatedNewsItem
      assigns[:translated_news_item].id.should == @translated_news_item_to_edit.id
      assigns[:translated_news_item].news_item_id.should == @news_item.id
      assigns[:translated_news_item].title.should == "Test Translated News"
      assigns[:translated_news_item].language.should == Language.english
      assigns[:translated_news_item].body.should == "Test Translated News Item Body"
      assigns[:translated_news_item].active_translation.should be_true
    end
  end

  describe 'PUT update' do
    before :all do
      TranslatedNewsItem.delete_all(:news_item_id => @news_item.id)
      @translated_news_item_to_update = TranslatedNewsItem.gen(:news_item_id => @news_item.id, :title => "Test Translated News",
                                        :language => Language.english, :body => "Test Translated News Item Body", :active_translation => true)
      @update_translated_news_item_params = { :news_item_id => @news_item.id, :id => @translated_news_item_to_update.id,
        :translated_news_item => { :title => "Update Test Translated News", :body => "Update Test Translated News Item Body",
                                   :language_id => Language.english.id, :active_translation => true } }
    end
    it 'should only allow access to EOL administrators' do
      put :update
      response.should redirect_to(login_url)
      expect{ get :new, { :id => @news_item.id }, { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should update a translated news item' do
      put :update, @update_translated_news_item_params, { :user => @admin, :user_id => @admin.id }
      assigns[:news_item].class.should == NewsItem
      assigns[:translated_news_item].class.should == TranslatedNewsItem
      assigns[:translated_news_item].title.should == "Update Test Translated News"
      assigns[:translated_news_item].body.should == "Update Test Translated News Item Body"
      flash[:notice].should == I18n.t(:admin_translated_news_item_update_successful_notice, :page_name => @news_item.page_name,
                              :language => Language.english.label, :anchor => @news_item.page_name.gsub(' ', '_').downcase)
      response.should redirect_to(news_items_path(:anchor => @news_item.page_name.gsub(' ', '_').downcase))
    end
  end

  describe 'DELETE destroy' do
    before :all do
      TranslatedNewsItem.delete_all(:news_item_id => @news_item.id)
    end
    it 'should only allow access to EOL administrators' do
      delete :destroy
      response.should redirect_to(login_url)
      expect{ get :new, { :id => @news_item.id }, { :user => @non_admin, :user_id => @non_admin.id } }.to raise_error(EOL::Exceptions::SecurityViolation)
    end
    it 'should delete a translated news item' do
      @translated_news_item_to_delete ||=
        TranslatedNewsItem.gen(:news_item_id => @news_item.id, :title => "Test Translated News",
                               :language => Language.english, :body => "Test Translated News Item Body",
                               :active_translation => true)
      @delete_translated_news_item_params =
        { :news_item_id => @news_item.id, :id => @translated_news_item_to_delete.id }
      delete :destroy, @delete_translated_news_item_params, { :user => @admin, :user_id => @admin.id }
      flash[:notice].should == I18n.t(:admin_translated_news_item_delete_successful_notice, :page_name => @news_item.page_name, :language => Language.english.label)
      response.should redirect_to(news_items_path)
    end
  end

end
