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
    visit('/login')
    body.should have_tag('form[action="/sessions"]') do
      with_tag('input#session_username_or_email')
      with_tag('input#session_password')
    end
  end

  it 'should redirect us back to login if we logged in incorrectly' do
    login_as User.new(:username => 'snoopy', :password => 'wrongtotallywrong')
    #submitting a wrong password should re-render the login page
    current_path.should == '/login'
  end

  it 'should tell us if we logged in incorrectly' do
    # first, we fail a login attempt
    login_as User.new(:username => 'snoopy', :password => 'wrongtotallywrong')
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
    body.should_not have_tag(".session .details p strong", :text => user.short_name)
    login_as user
    body.should have_tag(".session .details p strong", :text => user.short_name)
  end

  it 'should be able to logout user' do
    user = User.gen
    login_as user
    body.should have_tag('.session .details p strong', :text => user.short_name)
    visit('/logout')
    visit user_path(user)
    body.should_not have_tag('.session .details p strong', :text => user.short_name)
  end

  it 'should redirect user to return_to url if user successfully log in after a failed attempt' do
    user = User.gen
    comment = "Test comment by anonymous user."
    visit("/data_objects/#{DataObject.last.id}")
    body.should_not have_tag("blockquote", :text => comment)
    body.should have_tag(".comment #comment_body")
    body.should have_tag("#new_comment .actions input", :val => "Post Comment")
    within(:xpath, '//form[@id="new_comment"]') do
      fill_in 'comment_body', :with => comment
      click_button "Post Comment"
    end
    current_path.should == '/login'
    fill_in 'session_username_or_email', :with => 'snoopy'
    fill_in 'session_password', :with => 'wrongtotallywrong'
    click_button 'Sign in'
    body.should include('Login failed')
    current_path.should == '/login'
    fill_in 'session_username_or_email', :with => user.username
    fill_in 'session_password', :with => user.password
    # TODO - legitimate failure. In Rails 3, a post is a post is a post is a post, and when we redirect, we GET.
    click_button 'Sign in'
    current_path.should == data_object_path(DataObject.last.id)
    body.should include('Comment successfully added.')
    body.should have_tag("blockquote", :text => comment)
  end

  it 'should redirect user to return_to url if user successfully log in after a failed attempt' do
    user = User.gen
    comment = "Test comment by anonymous user."
    visit("/data_objects/#{DataObject.last.id}")
    body.should_not have_tag("blockquote", :text => comment)
    body.should have_tag(".comment #comment_body")
    body.should have_tag("#new_comment .actions input", :val => "Post Comment")
    within(:xpath, '//form[@id="new_comment"]') do
      fill_in 'comment_body', :with => comment
      click_button "Post Comment"
    end
    current_path.should == '/login'
    fill_in 'session_username_or_email', :with => 'snoopy'
    fill_in 'session_password', :with => 'wrongtotallywrong'
    click_button 'Sign in'
    body.should include('Login failed')
    current_path.should == '/login'
    fill_in 'session_username_or_email', :with => user.username
    fill_in 'session_password', :with => user.password
    click_button 'Sign in'
    current_path.should == data_object_path(DataObject.last.id)
    body.should include('Comment successfully added.')
    body.should have_tag("blockquote", :text => comment)
  end

end

