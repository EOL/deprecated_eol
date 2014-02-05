require "spec_helper"

describe PermissionsController do

  before(:all) do
    @admin = User.gen(:admin => true)
  end

  before(:each) do
    TranslatedPermission.delete_all
    Permission.delete_all
    @permission = TranslatedPermission.gen.permission
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # PermissionsController. Be sure to keep this updated too.
  def valid_session
    {:user => @admin, :user_id => @admin.id}
  end

  describe "GET index" do
    it "assigns all permissions as @permissions" do
      get :index, {}, valid_session
      assigns(:permissions).should eq([@permission])
    end
  end

  describe "GET show" do
    it "assigns the requested permission as @permission" do
      permission = Permission.gen
      get :show, {:id => @permission.to_param}, valid_session
      assigns(:permission).should eq(@permission)
    end
  end

end
