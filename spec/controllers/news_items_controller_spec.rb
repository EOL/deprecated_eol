require File.dirname(__FILE__) + '/../spec_helper'

describe NewsItemsController do

  before(:all) do
    unless @admin = User.find_by_username('admins_controller_specs')
      truncate_all_tables
      load_foundation_cache
      @admin = User.gen(:username => 'admins_controllers_specs', :password => "password", :admin => true)
    end
    @news_item_1 = NewsItem.gen(:page_name => "test_translated_news_item_1", :active => true, :user => @admin, :display_date => "2012-07-13 20:20:00 UTC")
    @translated_news_item_1 = TranslatedNewsItem.gen(:news_item_id => @news_item_1.id, :title => "Test Translated News1",
                                      :language => Language.english, :body => "Test Translated News Item Body1", :active_translation => true)
    @news_item_2 = NewsItem.gen(:page_name => "test_translated_news_item_2", :active => true, :user => @admin, :display_date => "2012-07-14 20:20:00 UTC")
    @translated_news_item_2 = TranslatedNewsItem.gen(:news_item_id => @news_item_2.id, :title => "Test Translated News2",
                                      :language => Language.english, :body => "Test Translated News Item Body2", :active_translation => true)
  end

  describe 'GET index' do
    it "should instantiate page_title and translated news items in descending order of display_date" do
      get :index
      assigns[:page_title].should == I18n.t(:page_title, :scope => [:news_items, :index])
      assigns[:translated_news_items].count.should == 2
      assigns[:translated_news_items].first.id.should == @translated_news_item_2.id
      assigns[:translated_news_items].last.id.should == @translated_news_item_1.id
    end
  end

  describe 'GET show' do
    it "should redirect to news item page" do
      get :show, {:id => @news_item_2.id, :language => Language.english.iso_639_1}
      assigns[:page_title] = @translated_news_item_2.title
      assigns[:selected_language] = Language.english
      assigns[:translated_news_item] = @translated_news_item_2
    end
  end

end