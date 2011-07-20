require File.dirname(__FILE__) + '/../spec_helper'

describe 'account/reset_password' do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @user_token = '123'
    @expired_token = '456'
    @user = User.gen(:username => 'johndoe', :email => 'johndoe@example.com')
    @user_expired = User.gen(:username => 'janedoe', :email => 'janedoe@example.com')
  end

  before(:each) do
    @user.update_attribute(:password_reset_token, @user_token)
    @user.update_attribute(:password_reset_token_expires_at, 1.hour.from_now)
    @user_expired.update_attribute(:password_reset_token, @expired_token)
    @user_expired.update_attribute(:password_reset_token_expires_at, 1.hour.ago)
  end

  it 'should redirect to home page if token is not found' do
    visit("/account/reset_password/abc")
    current_path.should == '/account/forgot_password'
  end

  it 'should redirect to the home page and delete token if token is expired' do
    visit("/account/reset_password/#{@user_expired.password_reset_token}")
    current_path.should == '/account/forgot_password'
    User.find(@user_expired).password_reset_token.should be_nil
    User.find(@user_expired).password_reset_token_expires_at.should be_nil
  end

  it 'should render the page and show the form for existing token' do
    visit("/account/reset_password/#{@user.password_reset_token}")
    page.status_code.should == 200
    body.should_not include '500 Internal Server Error'
    body.should have_tag('form') do |f|
      f.should have_tag('input#user_entered_password')
      f.should have_tag('input#user_entered_password_confirmation')
      f.should have_tag('input[type=submit]')
    end
    User.find(@user).password_reset_token.should be_nil
    User.find(@user).password_reset_token_expires_at.should be_nil
  end

end
