require File.dirname(__FILE__) + '/../../spec_helper'

describe Administrator::CuratorController do
  before(:all) do
    truncate_all_tables
    Language.create_english
    CuratorLevel.create_defaults
    @curator = User.gen(:curator_level => CuratorLevel.full_curator, :credentials => 'Blah', :curator_scope => 'More blah')
    @user_wants_to_be_curator = User.gen(:requested_curator_level_id => CuratorLevel.full_curator.id, :credentials => 'Blah', :curator_scope => 'More blah')
    @admin = User.gen(:username => "admin", :password => "admin")
    @admin.grant_admin
  end

  it "should set @users when accessing GET /index" do
    session[:user_id] = @admin.id
    get :index
    assigns[:users].should_not be_nil
    assigns[:users].should include(@curator)
    assigns[:users].should include(@user_wants_to_be_curator)
  end

  it "should set @users when accessing GET /index for unapproved curators" do
    session[:user_id] = @admin.id
    get :index, { :only_unapproved => true }
    assigns[:users].should_not be_nil
    assigns[:users].should_not include(@curator)
    assigns[:users].should include(@user_wants_to_be_curator)
  end

  it "should not be accessible to non-admin users" do
    session[:user_id] = @curator.id
    lambda { get :index }.should raise_error(EOL::Exceptions::SecurityViolation)
  end

end
