require 'spec_helper'

describe TaskNamesController do

  def mock_task_name(stubs={})
    @mock_task_name ||= mock_model(TaskName, stubs)
  end

  describe "GET index" do
    it "assigns all task_names as @task_names" do
      TaskName.stub(:find).with(:all).and_return([mock_task_name])
      get :index
      assigns[:task_names].should == [mock_task_name]
    end
  end

  describe "GET show" do
    it "assigns the requested task_name as @task_name" do
      TaskName.stub(:find).with("37").and_return(mock_task_name)
      get :show, :id => "37"
      assigns[:task_name].should equal(mock_task_name)
    end
  end

  describe "GET new" do
    it "assigns a new task_name as @task_name" do
      TaskName.stub(:new).and_return(mock_task_name)
      get :new
      assigns[:task_name].should equal(mock_task_name)
    end
  end

  describe "GET edit" do
    it "assigns the requested task_name as @task_name" do
      TaskName.stub(:find).with("37").and_return(mock_task_name)
      get :edit, :id => "37"
      assigns[:task_name].should equal(mock_task_name)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created task_name as @task_name" do
        TaskName.stub(:new).with({'these' => 'params'}).and_return(mock_task_name(:save => true))
        post :create, :task_name => {:these => 'params'}
        assigns[:task_name].should equal(mock_task_name)
      end

      it "redirects to the created task_name" do
        TaskName.stub(:new).and_return(mock_task_name(:save => true))
        post :create, :task_name => {}
        response.should redirect_to(task_name_url(mock_task_name))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved task_name as @task_name" do
        TaskName.stub(:new).with({'these' => 'params'}).and_return(mock_task_name(:save => false))
        post :create, :task_name => {:these => 'params'}
        assigns[:task_name].should equal(mock_task_name)
      end

      it "re-renders the 'new' template" do
        TaskName.stub(:new).and_return(mock_task_name(:save => false))
        post :create, :task_name => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested task_name" do
        TaskName.should_receive(:find).with("37").and_return(mock_task_name)
        mock_task_name.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :task_name => {:these => 'params'}
      end

      it "assigns the requested task_name as @task_name" do
        TaskName.stub(:find).and_return(mock_task_name(:update_attributes => true))
        put :update, :id => "1"
        assigns[:task_name].should equal(mock_task_name)
      end

      it "redirects to the task_name" do
        TaskName.stub(:find).and_return(mock_task_name(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(task_name_url(mock_task_name))
      end
    end

    describe "with invalid params" do
      it "updates the requested task_name" do
        TaskName.should_receive(:find).with("37").and_return(mock_task_name)
        mock_task_name.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :task_name => {:these => 'params'}
      end

      it "assigns the task_name as @task_name" do
        TaskName.stub(:find).and_return(mock_task_name(:update_attributes => false))
        put :update, :id => "1"
        assigns[:task_name].should equal(mock_task_name)
      end

      it "re-renders the 'edit' template" do
        TaskName.stub(:find).and_return(mock_task_name(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested task_name" do
      TaskName.should_receive(:find).with("37").and_return(mock_task_name)
      mock_task_name.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the task_names list" do
      TaskName.stub(:find).and_return(mock_task_name(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(task_names_url)
    end
  end

end
