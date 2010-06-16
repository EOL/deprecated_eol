require File.dirname(__FILE__) + '/../spec_helper'

describe 'Login' do

  before :all do
    EolScenario.load :foundation
  end
  after :all do
    truncate_all_tables
  end

  # specs

  it 'login page should render OK' do
    request('/login').body.should have_tag('form[action="/account/authenticate"]') do
      with_tag('input#user_username')
      with_tag('input#user_password')
    end
  end

  it 'should redirect us back to login if we logged in incorrectly' do
    resp = login_as :username => 'snoopy', :password => 'wrongtotallywrong'
    resp.should be_redirect
    resp.should redirect_to('/login')
  end

  it 'should tell us if we logged in incorrectly' do
    # first, we fail a login attempt
    login_as( :username => 'snoopy', :password => 'wrongtotallywrong').should be_redirect
    # ^ it'll redirect us back to login ... when we get there, we should have a flash message
    request('/login').body.should include('Invalid login')
  end

  it 'should redirect to index after a successful login' do
    user = User.gen :username => 'charliebrown'
    login_as(user).should redirect_to('/')
  end
  
  it 'should set a remember token for us if we asked to be remembered' do
    user = User.gen :username => 'charliebrown'
    login_as(user, :remember_me => '1').should redirect_to('/')
    User.find_by_username('charliebrown').remember_token.should_not be_blank
  end

  it 'should say hello to the user after logging in' do
    user = User.gen :username => 'charliebrown'
    request('/').should_not include_text("Hello #{ user.given_name }")
    login_as(user).should redirect_to('/')
    request('/').should include_text("Hello #{ user.given_name }")
  end
  
  it 'logout should work' do
    user = User.gen :username => 'charliebrown'

    login_as(user).should redirect_to('/')
    request('/').body.should have_tag('div.desc-personal') do
      with_tag('p', :text => /Hello #{ user.given_name }/)
    end
    request('/logout').should be_redirect
    request('/').body.should have_tag('div.desc-personal') do
      without_tag('p', :text => /Hello #{ user.given_name }/)
    end
  end
  
  it 'should not show the curator link and name must not have hyperlink to profile page' do
    user = User.gen :username => 'charliebrown'
    login_as(user)
    request('/').should_not include_text('curators')
    request('/').should_not include_text("/account/show/")
  end
  
  describe "as a curator" do
    it "should show the curator link and name must have hyperlink to profile page" do
      curator = build_curator(HierarchyEntry.gen, :username => 'test_curator')
      login_as(curator)
      request('/').should include_text("curators")
      request('/').should include_text("/account/show/")
    end
  end


  
end
