require File.dirname(__FILE__) + '/../spec_helper'

describe RedirectsController do

  describe 'GET show' do
    it 'should permanently redirect to URLs when URL parameter is provided' do
      url = 'http://www.google.com'
      get :show, :url => url
      response.redirected_to.should == url
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to CMS pages when CMS page id parameter is provided' do
      get :show, :cms_page_id => 'news'
      response.redirected_to.should == cms_page_path('news')
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to taxon page when taxon id parameter is provided' do
      get :show, :taxon_id => '1'
      response.redirected_to.should == taxon_overview_path(1)
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to media tab when calling /pages/#/images' do
      get :show, :taxon_id_images => '1'
      response.redirected_to.should == taxon_media_path(1)
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to media tab when calling /pages/#/classification_attribution' do
      get :show, :taxon_id_classification_attribution => '1'
      response.redirected_to.should == taxon_names_path(1)
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to user profile when user id parameter is provided' do
      get :show, :user_id => '1'
      response.redirected_to.should == user_path(1)
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to collection when collection id parameter is provided' do
      get :show, :collection_id => '1'
      response.redirected_to.should == collection_path(1)
      response.status.should == '301 Moved Permanently'
    end
    it 'should default to premenantly redirecting to /' do
      get :show
      response.redirected_to.should == :root
      response.status.should == '301 Moved Permanently'
    end
  end

end
