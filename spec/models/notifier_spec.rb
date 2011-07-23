require File.dirname(__FILE__) + '/../spec_helper'

describe Notifier do
  describe 'reset_password' do
    before(:all) do
      @user = User.gen(:username => "johndoe", :email => "johndoe@example.com", :given_name => "John",
                       :password_reset_token => User.generate_key)
      @email = Notifier.create_reset_password(@user, "/users/#{@user.id}/reset_password/#{@user.password_reset_token}")
    end

    it "should be set to be delivered to the email passed in" do
      @email.should deliver_to(@user.email)
    end

    it "should be addressed by short name" do
      @email.should have_text(/Dear John/)
    end

    it "should contain a link for resetting password" do
      @email.should have_text(/users\/#{@user.id}\/reset_password\/#{@user.password_reset_token}/i)
    end

    it "should have the correct subject" do
      @email.should have_subject(/password reset/i)
    end
  end
end
