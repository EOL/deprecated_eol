require File.dirname(__FILE__) + '/../spec_helper'

describe AccountController do

     describe "POST /account/forgot_password" do
        it "should deliver the signup email" do
          user = User.gen(:username => 'johndoe', :email => 'johndoe@example.com')
          user.save!
          # expect
          Notifier.should_receive(:deliver_forgot_password_email).with(user, 80)
          # when
          post :forgot_password, "user" => {"email" => "johndoe@example.com", "username" => "johndoe"}
        end
      end


end
