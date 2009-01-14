class RandomImagesController < ApplicationController
	
	
	
  # GET /random_images
  # GET /random_images.xml
  def index
		limit = 10
		offset = rand(RandomImage.count) - limit
		offset = 0 if offset < 0
		#offset = 1000
    # @random_images = RandomImage.find(:all, :include => [:data_object, {:hierarchy => [:hierarchy_name]}], :offset => offset, :limit => 10)
		@random_images = RandomImage.find(:all, :include => [:data_object, :hierarchy], :offset => offset, :limit => 10)
		# @random_images = RandomImage.find(:all, :offset => offset, :limit => 10)
		
    respond_to do |format|
      format.html # :layout => 'main' # index.html.erb
      format.xml  # { render :xml => @random_images }
    end
  end

  # GET /random_images/1
  # GET /random_images/1.xml
  def show
    @random_image = RandomImage.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @random_image }
    end
  end

  # GET /random_images/new
  # GET /random_images/new.xml
  def new
    @random_image = RandomImage.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @random_image }
    end
  end

  # GET /random_images/1/edit
  def edit
    @random_image = RandomImage.find(params[:id])
  end

  # POST /random_images
  # POST /random_images.xml
  def create
    @random_image = RandomImage.new(params[:random_image])

    respond_to do |format|
      if @random_image.save
        flash[:notice] = 'RandomImage was successfully created.'
        format.html { redirect_to(@random_image) }
        format.xml  { render :xml => @random_image, :status => :created, :location => @random_image }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @random_image.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /random_images/1
  # PUT /random_images/1.xml
  def update
    @random_image = RandomImage.find(params[:id])

    respond_to do |format|
      if @random_image.update_attributes(params[:random_image])
        flash[:notice] = 'RandomImage was successfully updated.'
        format.html { redirect_to(@random_image) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @random_image.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /random_images/1
  # DELETE /random_images/1.xml
  def destroy
    @random_image = RandomImage.find(params[:id])
    @random_image.destroy

    respond_to do |format|
      format.html { redirect_to(random_images_url) }
      format.xml  { head :ok }
    end
  end
end
