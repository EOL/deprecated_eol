require "spec_helper"

describe 'user recover account' do

  before(:all) do
    load_foundation_cache
    Capybara.reset_sessions!
    @user_token = Digest::SHA1.hexdigest('123')
    @expired_token = Digest::SHA1.hexdigest('456')
    @user = User.gen(username: 'johndoe', email: 'johndoe@example.com',
                     recover_account_token: @user_token,
                     recover_account_token_expires_at: 1.hour.from_now)
    @user_expired = User.gen(username: 'janedoe', email: 'janedoe@example.com',
                             recover_account_token: @expired_token,
                             recover_account_token_expires_at: 1.hour.ago)
  end

  describe 'temporary login' do
    it 'should redirect to recover account if token does not match user token' do
      visit temporary_login_user_path(@user.id, Digest::SHA1.hexdigest('notarealtoken'))
      current_path.should == recover_account_users_path
    end

    it 'should redirect to recover account and delete token if token is expired' do
      visit temporary_login_user_path(@user_expired.id, @user_expired.recover_account_token)
      current_path.should == recover_account_users_path
      User.find(@user_expired).recover_account_token.should be_nil
      User.find(@user_expired).recover_account_token_expires_at.should be_nil
    end

    it 'should log user in and redirect to user edit for valid recover account token' do
      visit temporary_login_user_path(@user.id, @user.recover_account_token)
      #TODO: update for open authentication logins
      body.should have_selector('input#user_entered_password')
      body.should have_selector('input#user_entered_password_confirmation')
      body.should have_selector('input[type=submit]')
      User.find(@user).recover_account_token.should be_nil
      User.find(@user).recover_account_token_expires_at.should be_nil
    end
  end
end
