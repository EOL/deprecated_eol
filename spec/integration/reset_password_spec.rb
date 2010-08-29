require File.dirname(__FILE__) + '/../spec_helper' 

describe 'account/reset_password' do

  before(:all) do
    truncate_all_tables
    EolScenario.load :foundation
    Capybara.reset_sessions!
    @user = User.gen(:username => 'johndoe', :email => 'johndoe@example.com', :password_reset_token => '123', :password_reset_token_expires_at => 1.hour.from_now)
    @user.save!
    @user_expired = User.gen(:username => 'janedoe', :email => 'janedoe@example.com', :password_reset_token => '456', :password_reset_token_expires_at => 1.hour.ago)
    @user_expired.save!
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


  it 'should render the page for existing token' do
    visit("/account/reset_password/#{@user.password_reset_token}")
    page.status_code.should == 200
    body.should_not include '500 Internal Server Error'
    User.find(@user).password_reset_token.should be_nil
    User.find(@user).password_reset_token_expires_at.should be_nil
  end
  
  it 'should show form' do
    visit("/account/reset_password/#{@user.password_reset_token}")
    body.should have_tag('form#form_reset_password') do |f|
      f.should have_tag('input#user_entered_password')
      f.should have_tag('input#user_entered_password_confirmation')
      f.should have_tag('input[type=submit]')
    end
  end

end
