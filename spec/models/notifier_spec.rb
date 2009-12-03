require File.dirname(__FILE__) + '/../spec_helper'

describe Notifier do
  describe 'forgot_password_email' do
    before(:all) do
      @user = User.gen(:username => 'johndoe', :email => 'johndoe@example.com')
      @email = Notifier.create_forgot_password_email(@user, 80)
    end

    it "should be set to be delivered to the email passed in" do
      @email.should deliver_to(@user.email)
    end

    it "should contain the user's message in the mail body" do
      @email.should have_text(/johndoe/)
    end

    it "should contain a link for resetting password" do
      link = @user.password_reset_url(80)
      @email.should have_text(/link/)
    end

    it "should have the correct subject" do
      @email.should have_subject(/EOL Forgot Password/)
    end
  end
end
