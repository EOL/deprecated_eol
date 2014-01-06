class LocationsController < ApplicationController

  layout 'v2/basic'

  # GET /locations/new
  # GET /locations/new.json
  def new
    @location = Location.new
    @page_title = I18n.t('locations.what_lives_near_here_question')

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @location }
    end
  end

  # POST /locations
  # POST /locations.json
  def create
    @location = Location.new(params[:location])

    respond_to do |format|
      if @location.save
        format.html { redirect_to @location, notice: 'Location was successfully created.' }
        format.json { render json: @location, status: :created, location: @location }
      else
        format.html { render action: "new" }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

end
