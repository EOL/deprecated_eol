require File.dirname(__FILE__) + '/../spec_helper'

def create_user username, password
  user = User.gen :username => username, :password => password
  user.password = password
  user.save!
  user
end

describe 'Users' do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @username = 'userprofilespec'
    @password = 'beforeall'
    @user     = create_user(@username, @password)
    @watch_collection = @user.watch_collection
    @anon_user = User.gen(:password => 'password')
  end

  after(:each) do
    visit('/logout')
  end

  it 'should allow users to change filter content hierarchy (obsolete?)' # do
#    login_as @user
#    visit('/account/site_settings')
#    body.should_not have_tag('#header a[href*=?]', /login/)
#    body.should include('Filter EOL')
#    body.should have_tag('input#user_filter_content_by_hierarchy')
#  end

  it 'should generate api key' # do
#    login_as @user
#    visit edit_user_path(@user)
#    click_button 'Generate a key'
#    body.should_not include("Generate a key")
#    body.should have_tag('dt', 'API key')
#  end

  describe 'collections' do
    before(:each) do
      visit(user_collections_path(@user))
    end
    it 'should show their watch collection' do
      page.body.should have_tag('#collections_tab', /#{@watch_collection.name}/)
    end
  end

  describe 'newsfeed' do
    it 'should show a newsfeed'
    it 'should allow comments to be added' do
#      visit logout_url
#      visit user_path(@user)
#      page.fill_in 'comment_body', :with => "#{@anon_user.username} woz 'ere"
#      click_button 'Post Comment'
#      if current_url.match /#{login_url}/
#        page.fill_in 'session_username_or_email', :with => @anon_user.username
#        page.fill_in 'session_password', :with => 'password'
#        click_button 'Sign in'
#      end
#      current_url.should match /#{user_path(@user)}/
#      body.should include('Comment successfully added')
#      Comment.last.body.should match /#{@anon_user.username}/

      login_as @user
      visit user_newsfeed_path(@user)
      page.fill_in 'comment_body', :with => "#{@user.username} woz 'ere"
      click_button 'Post Comment'
      body.should include('Comment successfully added')
      Comment.last.body.should match /#{@user.username}/

      # test error handling when body is empty
      click_button 'Post Comment'
      body.should include('comment could not be added')
      visit logout_url
    end
  end

end
