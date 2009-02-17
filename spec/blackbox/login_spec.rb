require File.dirname(__FILE__) + '/../spec_helper'

describe 'Login' do

  scenario :foundation

  # helpers

  def create_user username, password
    Factory :user, :username => username, :entered_password => password
  end

  def login_as options = { }
    if options.is_a?User # let us pass a newly created user (with an entered_password)
      options = { :username => options.username, :password => options.entered_password }
    end
    request('/account/authenticate', :params => { 
        'user[username]' => options[:username], 
        'user[password]' => options[:password] })
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
    login_as( :username => 'snoopy', :password => 'secret' ).should be_redirect

    # ^ it'll redirect us back to login ... when we get there, we should have a flash message
    request('/login').body.should include('Invalid login')
  end

  it 'should redirect to index after a successful login' do
    @user = create_user 'charliebrown', 'testing'
    login_as( @user ).should redirect_to('/index')
  end

  it 'should say hello to the user after logging in' do
    @user = create_user 'charliebrown', 'testing'

    request('/').should_not include_text("Hello #{ @user.given_name }")
    login_as( @user ).should redirect_to('/index')
    request('/').should include_text("Hello #{ @user.given_name }")
  end
  
  it 'logout should work' do
    @user = create_user 'charliebrown', 'testing'

    login_as( @user ).should redirect_to('/index')
    request('/').should include_text("Hello #{ @user.given_name }")
    request('/logout')
    request('/').should_not include_text("Hello #{ @user.given_name }")
  end
  
end
