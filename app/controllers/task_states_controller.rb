class TaskStatesController < ApplicationController
  # GET /task_states
  # GET /task_states.xml
  def index
    @task_states = TaskState.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @task_states }
    end
  end

  # GET /task_states/1
  # GET /task_states/1.xml
  def show
    @task_state = TaskState.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @task_state }
    end
  end

  # GET /task_states/new
  # GET /task_states/new.xml
  def new
    @task_state = TaskState.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @task_state }
    end
  end

  # GET /task_states/1/edit
  def edit
    @task_state = TaskState.find(params[:id])
  end

  # POST /task_states
  # POST /task_states.xml
  def create
    @task_state = TaskState.new(params[:task_state])

    respond_to do |format|
      if @task_state.save
        format.html { redirect_to(@task_state, :notice => 'TaskState was successfully created.') }
        format.xml  { render :xml => @task_state, :status => :created, :location => @task_state }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @task_state.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /task_states/1
  # PUT /task_states/1.xml
  def update
    @task_state = TaskState.find(params[:id])

    respond_to do |format|
      if @task_state.update_attributes(params[:task_state])
        format.html { redirect_to(@task_state, :notice => 'TaskState was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @task_state.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /task_states/1
  # DELETE /task_states/1.xml
  def destroy
    @task_state = TaskState.find(params[:id])
    @task_state.destroy

    respond_to do |format|
      format.html { redirect_to(task_states_url) }
      format.xml  { head :ok }
    end
  end
end
