require 'spec_helper'

describe TaskStatesController do

  def mock_task_state(stubs={})
    @mock_task_state ||= mock_model(TaskState, stubs)
  end

  describe "GET index" do
    it "assigns all task_states as @task_states" do
      TaskState.stub(:find).with(:all).and_return([mock_task_state])
      get :index
      assigns[:task_states].should == [mock_task_state]
    end
  end

  describe "GET show" do
    it "assigns the requested task_state as @task_state" do
      TaskState.stub(:find).with("37").and_return(mock_task_state)
      get :show, :id => "37"
      assigns[:task_state].should equal(mock_task_state)
    end
  end

  describe "GET new" do
    it "assigns a new task_state as @task_state" do
      TaskState.stub(:new).and_return(mock_task_state)
      get :new
      assigns[:task_state].should equal(mock_task_state)
    end
  end

  describe "GET edit" do
    it "assigns the requested task_state as @task_state" do
      TaskState.stub(:find).with("37").and_return(mock_task_state)
      get :edit, :id => "37"
      assigns[:task_state].should equal(mock_task_state)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created task_state as @task_state" do
        TaskState.stub(:new).with({'these' => 'params'}).and_return(mock_task_state(:save => true))
        post :create, :task_state => {:these => 'params'}
        assigns[:task_state].should equal(mock_task_state)
      end

      it "redirects to the created task_state" do
        TaskState.stub(:new).and_return(mock_task_state(:save => true))
        post :create, :task_state => {}
        response.should redirect_to(task_state_url(mock_task_state))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved task_state as @task_state" do
        TaskState.stub(:new).with({'these' => 'params'}).and_return(mock_task_state(:save => false))
        post :create, :task_state => {:these => 'params'}
        assigns[:task_state].should equal(mock_task_state)
      end

      it "re-renders the 'new' template" do
        TaskState.stub(:new).and_return(mock_task_state(:save => false))
        post :create, :task_state => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested task_state" do
        TaskState.should_receive(:find).with("37").and_return(mock_task_state)
        mock_task_state.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :task_state => {:these => 'params'}
      end

      it "assigns the requested task_state as @task_state" do
        TaskState.stub(:find).and_return(mock_task_state(:update_attributes => true))
        put :update, :id => "1"
        assigns[:task_state].should equal(mock_task_state)
      end

      it "redirects to the task_state" do
        TaskState.stub(:find).and_return(mock_task_state(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(task_state_url(mock_task_state))
      end
    end

    describe "with invalid params" do
      it "updates the requested task_state" do
        TaskState.should_receive(:find).with("37").and_return(mock_task_state)
        mock_task_state.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :task_state => {:these => 'params'}
      end

      it "assigns the task_state as @task_state" do
        TaskState.stub(:find).and_return(mock_task_state(:update_attributes => false))
        put :update, :id => "1"
        assigns[:task_state].should equal(mock_task_state)
      end

      it "re-renders the 'edit' template" do
        TaskState.stub(:find).and_return(mock_task_state(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested task_state" do
      TaskState.should_receive(:find).with("37").and_return(mock_task_state)
      mock_task_state.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the task_states list" do
      TaskState.stub(:find).and_return(mock_task_state(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(task_states_url)
    end
  end

end
