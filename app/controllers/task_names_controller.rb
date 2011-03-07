class TaskNamesController < ApplicationController
  # GET /task_names
  # GET /task_names.xml
  def index
    @task_names = TaskName.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @task_names }
    end
  end

  # GET /task_names/1
  # GET /task_names/1.xml
  def show
    @task_name = TaskName.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @task_name }
    end
  end

  # GET /task_names/new
  # GET /task_names/new.xml
  def new
    @task_name = TaskName.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @task_name }
    end
  end

  # GET /task_names/1/edit
  def edit
    @task_name = TaskName.find(params[:id])
  end

  # POST /task_names
  # POST /task_names.xml
  def create
    @task_name = TaskName.new(params[:task_name])

    respond_to do |format|
      if @task_name.save
        format.html { redirect_to(@task_name, :notice => 'TaskName was successfully created.') }
        format.xml  { render :xml => @task_name, :status => :created, :location => @task_name }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @task_name.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /task_names/1
  # PUT /task_names/1.xml
  def update
    @task_name = TaskName.find(params[:id])

    respond_to do |format|
      if @task_name.update_attributes(params[:task_name])
        format.html { redirect_to(@task_name, :notice => 'TaskName was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @task_name.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /task_names/1
  # DELETE /task_names/1.xml
  def destroy
    @task_name = TaskName.find(params[:id])
    @task_name.destroy

    respond_to do |format|
      format.html { redirect_to(task_names_url) }
      format.xml  { head :ok }
    end
  end
end
