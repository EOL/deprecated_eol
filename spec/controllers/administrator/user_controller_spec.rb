require File.dirname(__FILE__) + '/../../spec_helper'

describe Administrator::UserController do
  before(:all) do
    truncate_all_tables
    Language.create_english
    @admin = User.gen(:username => "admin", :password => "admin")
    @admin.grant_admin
    @non_admin = User.gen(:username => "non_admin", :password => "non_admin")
    @user = User.gen(:username => "user", :password => "user")
  end
  describe "GET deactivate" do
    context "when current_user is admin" do
      before do
        session[:user_id] = @admin.id
        allow(controller).to receive(:current_user) { @admin }
      end
      it "allows admin to deactivate users" do
        get :deactivate, id: @user.id
        expect(User.find(@user.id).is_active?).to be_false
      end
      it "doesn't allow admin to deactivate himself" do
        get :deactivate, id: @admin.id
        expect { @admin.active }.to be_true
      end
    end
    context "when current_user is not admin" do
      before do
        @non_admin.update_column(:active, true)
        @user.update_column(:active, true)
        session[:user_id] = @non_admin.id
        allow(controller).to receive(:current_user) { @non_admin }
      end
      it "doesn't allow non admin to deactivate himself" do
        expect { get :deactivate, id: @non_admin.id }.to raise_error
        expect { @admin.active }.to be_true
      end
      it "doesn't allow non admin to deactivate any user" do
        expect { get :deactivate, id: @user.id }.to raise_error
        expect { @user.active }.to be_true
      end
    end
    
    context "when there isn't any logged in user" do
      before do
        session[:user_id] = nil
        allow(controller).to receive(:current_user) { nil }
      end
      it "doesn't allow to deactivate any user" do
        get :deactivate, id: @user.id
        expect { @user.active }.to be_true
      end
    end
  end
end