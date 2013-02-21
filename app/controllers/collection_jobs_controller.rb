class CollectionJobsController < ApplicationController
  # GET /collection_jobs
  # GET /collection_jobs.json
  def index
    @collection_jobs = CollectionJob.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @collection_jobs }
    end
  end

  # GET /collection_jobs/1
  # GET /collection_jobs/1.json
  def show
    @collection_job = CollectionJob.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @collection_job }
    end
  end

  # GET /collection_jobs/new
  # GET /collection_jobs/new.json
  def new
    @collection_job = CollectionJob.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @collection_job }
    end
  end

  # GET /collection_jobs/1/edit
  def edit
    @collection_job = CollectionJob.find(params[:id])
  end

  # POST /collection_jobs
  # POST /collection_jobs.json
  def create
    @collection_job = CollectionJob.new(params[:collection_job])

    respond_to do |format|
      if @collection_job.save
        format.html { redirect_to @collection_job, notice: 'Collection job was successfully created.' }
        format.json { render json: @collection_job, status: :created, location: @collection_job }
      else
        format.html { render action: "new" }
        format.json { render json: @collection_job.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /collection_jobs/1
  # PUT /collection_jobs/1.json
  def update
    @collection_job = CollectionJob.find(params[:id])

    respond_to do |format|
      if @collection_job.update_attributes(params[:collection_job])
        format.html { redirect_to @collection_job, notice: 'Collection job was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @collection_job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /collection_jobs/1
  # DELETE /collection_jobs/1.json
  def destroy
    @collection_job = CollectionJob.find(params[:id])
    @collection_job.destroy

    respond_to do |format|
      format.html { redirect_to collection_jobs_url }
      format.json { head :no_content }
    end
  end
end
