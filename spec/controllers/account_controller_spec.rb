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

      describe "POST /account/save_reset_password" do
        it "should change password for a user" do
          user = User.gen(:username => 'johndoe', :email => 'johndoe@example.com')
          user.save!
          new_password = "newpass"
          old_hashed_password = User.find(user).hashed_password
          post :save_reset_password, "user" => {"id" => user.id, "entered_password" => new_password, "entered_password_confirmation" => new_password}
          User.find(user).hashed_password.should_not == old_hashed_password
          User.find(user).hashed_password.should == User.hash_password(new_password)
        end
      end

      describe "POST /account/signup" do
        it "should create agent record for a user during account creation" do
          Scenario.load :foundation
          post :signup, "user" => {"username" => "johndoe99", "email" => "johndoe99@example.com", "entered_password" => "password", "entered_password_confirmation" => "password", "given_name" => "John"}
          User.find_by_username("johndoe99").agent_id.to_i.should > 0
        end
      end

end
