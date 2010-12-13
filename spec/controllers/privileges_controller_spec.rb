require 'spec_helper'

describe PrivilegesController do

  def mock_privilege(stubs={})
    @mock_privilege ||= mock_model(Privilege, stubs)
  end

  describe "GET index" do
    it "assigns all privileges as @privileges" do
      Privilege.stub(:find).with(:all).and_return([mock_privilege])
      get :index
      assigns[:privileges].should == [mock_privilege]
    end
  end

  describe "GET show" do
    it "assigns the requested privilege as @privilege" do
      Privilege.stub(:find).with("37").and_return(mock_privilege)
      get :show, :id => "37"
      assigns[:privilege].should equal(mock_privilege)
    end
  end

  describe "GET new" do
    it "assigns a new privilege as @privilege" do
      Privilege.stub(:new).and_return(mock_privilege)
      get :new
      assigns[:privilege].should equal(mock_privilege)
    end
  end

  describe "GET edit" do
    it "assigns the requested privilege as @privilege" do
      Privilege.stub(:find).with("37").and_return(mock_privilege)
      get :edit, :id => "37"
      assigns[:privilege].should equal(mock_privilege)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created privilege as @privilege" do
        Privilege.stub(:new).with({'these' => 'params'}).and_return(mock_privilege(:save => true))
        post :create, :privilege => {:these => 'params'}
        assigns[:privilege].should equal(mock_privilege)
      end

      it "redirects to the created privilege" do
        Privilege.stub(:new).and_return(mock_privilege(:save => true))
        post :create, :privilege => {}
        response.should redirect_to(privilege_url(mock_privilege))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved privilege as @privilege" do
        Privilege.stub(:new).with({'these' => 'params'}).and_return(mock_privilege(:save => false))
        post :create, :privilege => {:these => 'params'}
        assigns[:privilege].should equal(mock_privilege)
      end

      it "re-renders the 'new' template" do
        Privilege.stub(:new).and_return(mock_privilege(:save => false))
        post :create, :privilege => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested privilege" do
        Privilege.should_receive(:find).with("37").and_return(mock_privilege)
        mock_privilege.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :privilege => {:these => 'params'}
      end

      it "assigns the requested privilege as @privilege" do
        Privilege.stub(:find).and_return(mock_privilege(:update_attributes => true))
        put :update, :id => "1"
        assigns[:privilege].should equal(mock_privilege)
      end

      it "redirects to the privilege" do
        Privilege.stub(:find).and_return(mock_privilege(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(privilege_url(mock_privilege))
      end
    end

    describe "with invalid params" do
      it "updates the requested privilege" do
        Privilege.should_receive(:find).with("37").and_return(mock_privilege)
        mock_privilege.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :privilege => {:these => 'params'}
      end

      it "assigns the privilege as @privilege" do
        Privilege.stub(:find).and_return(mock_privilege(:update_attributes => false))
        put :update, :id => "1"
        assigns[:privilege].should equal(mock_privilege)
      end

      it "re-renders the 'edit' template" do
        Privilege.stub(:find).and_return(mock_privilege(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested privilege" do
      Privilege.should_receive(:find).with("37").and_return(mock_privilege)
      mock_privilege.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the privileges list" do
      Privilege.stub(:find).and_return(mock_privilege(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(privileges_url)
    end
  end

end
