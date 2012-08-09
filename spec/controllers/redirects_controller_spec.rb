require File.dirname(__FILE__) + '/../spec_helper'

describe RedirectsController do

  describe 'GET show' do
    it 'should permanently redirect to URLs when URL parameter is provided' do
      url = 'http://www.google.com'
      get :show, :url => url
      response.redirected_to.should == url
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to CMS pages when CMS page id is provided' do
      get :show, :cms_page_id => 'news'
      response.redirected_to.should == cms_page_path('news')
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to taxon overview when taxon id is provided' do
      get :show, :taxon_id => '1'
      response.redirected_to.should == taxon_overview_path(1)
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to taxon community curators when taxon id and sub tab are provided' do
      get :show, :taxon_id => '1', :sub_tab => 'curators'
      response.redirected_to.should == curators_taxon_community_path(1)
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to taxon maps when taxon id and sub tab are provided' do
      get :show, :taxon_id => '1', :sub_tab => 'maps'
      response.redirected_to.should == taxon_map_path(1)
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to taxon media when taxon id and sub tab are provided' do
      get :show, :taxon_id => '1', :sub_tab => 'media'
      response.redirected_to.should == taxon_media_path(1)
      response.status.should == '301 Moved Permanently'
    end
     it 'should permanently redirect to taxon names when taxon id and sub tab are provided' do
      get :show, :taxon_id => '1', :sub_tab => 'names'
      response.redirected_to.should == taxon_names_path(1)
      response.status.should == '301 Moved Permanently'
    end
   it 'should permanently redirect to user profile when user id is provided' do
      get :show, :user_id => '1'
      response.redirected_to.should == user_path(1)
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to temporary login when user id and recover account token are provided' do
      get :show, :user_id => '1', :recover_account_token => '12345'
      response.redirected_to.should == temporary_login_user_url(1, '12345')
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to recover account as conditional redirect' do
      get :show, :conditional_redirect_id => 'recover_account'
      response.redirected_to.should == recover_account_users_url
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to collection when collection id is provided' do
      get :show, :collection_id => '1'
      response.redirected_to.should == collection_path(1)
      response.status.should == '301 Moved Permanently'
    end
    it 'should permanently redirect to root by default if no other route found' do
      get :show
      response.redirected_to.should == :root
      response.status.should == '301 Moved Permanently'
    end
  end

end
