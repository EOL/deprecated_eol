require File.dirname(__FILE__) + '/../spec_helper'

describe 'Login' do
  before :all do
    load_foundation_cache
    Capybara.reset_sessions!
  end

  after :all do
    truncate_all_tables
  end

  after :each do
    visit('/logout')
  end

  it 'login page should render OK' do
    visit('/en/login')
    body.should have_tag('form[action="/en/sessions"]') do
      with_tag('input#session_username_or_email')
      with_tag('input#session_password')
    end
  end

  it 'should redirect us back to login if we logged in incorrectly' do
    login_as :username => 'snoopy', :password => 'wrongtotallywrong'
    #submitting a wrong password should re-render the login page
    current_path.should == '/en/login'
  end

  it 'should tell us if we logged in incorrectly' do
    # first, we fail a login attempt
    login_as( :username => 'snoopy', :password => 'wrongtotallywrong')
    body.should include('Login failed')
  end

  it 'should redirect to user show after a successful login' do
    user = User.gen
    login_as user
    current_path.should == user_newsfeed_path(user)
  end

  it 'should set a remember token for us if we asked to be remembered' do
    user = User.gen
    login_as(user, :remember_me => '1')
    current_path.should == user_newsfeed_path(user)
    user.reload.remember_token.should_not be_blank
  end

  it 'should indicate to user that they are logged in' do
    user = User.gen
    visit user_path(user)
    body.should_not have_tag('.session', /#{user.short_name}/)
    login_as user
    body.should have_tag('.session', /#{user.short_name}/)
  end

  it 'should be able to logout user' do
    user = User.gen
    login_as user
    body.should have_tag('.session', /#{user.short_name}/)
    visit('/logout')
    visit user_path(user)
    body.should_not have_tag('.session', /#{user.short_name}/)
  end

end

