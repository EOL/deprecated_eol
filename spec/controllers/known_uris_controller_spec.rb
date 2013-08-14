require File.dirname(__FILE__) + '/../spec_helper'

describe KnownUrisController do

  before(:all) do
    CuratorLevel.create_defaults
    @user = User.gen
    @full = FactoryGirl.create(:curator)
    @master = FactoryGirl.create(:master_curator)
    @admin = User.gen(:admin => true)
  end

  describe "GET index" do

    it "should work for admins" do
      get :index, {}, {:user => @admin, :user_id => @admin.id}
    end

    it "should work for master curators" do
      get :index, {}, {:user => @master, :user_id => @master.id}
    end

    it "should deny access for full curators" do
      expect {  get :index, {}, {:user => @full, :user_id => @full.id} }.to raise_error(EOL::Exceptions::SecurityViolation)
    end

  end

end
