require File.dirname(__FILE__) + '/../spec_helper'

describe 'Login' do

  before :all do
    Scenario.load :foundation
  end
  after :all do
    truncate_all_tables
  end

  # helpers

  def create_user username, password
    User.gen :username => username, :password => password
  end

  # specs

  it 'login page should render OK' do
    request('/login').body.should have_tag('form[action="/account/authenticate"]') do
      with_tag('input#user_username')
      with_tag('input#user_password')
    end
  end

  it 'should redirect us back to login if we logged in incorrectly' do
    resp = login_as :username => 'snoopy', :password => 'secret'
    resp.should be_redirect
    resp.should redirect_to('/login')
  end

  it 'should tell us if we logged in incorrectly' do
    # first, we fail a login attempt
    login_as( :username => 'snoopy', :password => 'secret',:remember_me=>'1' ).should be_redirect

    # ^ it'll redirect us back to login ... when we get there, we should have a flash message
    request('/login').body.should include('Invalid login')
  end

  it 'should redirect to index after a successful login' do
    user = create_user 'charliebrown', 'testing'
    login_as(user).should redirect_to('/')
  end
  
  it 'should set a remember token for us if we asked to be remembered' do
    user = create_user 'charliebrown', 'testing'
    login_as(:username => 'charliebrown', :password => 'testing',:remember_me=>'1' ).should(User.find_by_username('charliebrown').remember_token.empty? == false && redirect_to('/'))
  end

  it 'should say hello to the user after logging in' do
    user = create_user 'charliebrown', 'testing'
    request('/').should_not include_text("Hello #{ user.given_name }")
    login_as(user).should redirect_to('/')
    request('/').should include_text("Hello #{ user.given_name }")
  end
  
  it 'logout should work' do
    user = create_user 'charliebrown', 'testing'

    login_as(user).should redirect_to('/')
    request('/').should include_text("Hello #{ user.given_name }")
    request('/logout')
    request('/').should_not include_text("Hello #{ user.given_name }")
  end
  
  it 'should not show the curator link' do
    user = create_user 'charliebrown', 'testing'
    login_as(user)
    request('/').should_not include_text('curators')
  end
  
  describe "as a curator" do
    it "should show the curator link" do
      curator = build_curator(HierarchyEntry.gen, :username => 'test_curator', :password => 'test_password')
      login_as(curator)
      request('/').should include_text("curators")
    end
  end
  
end
