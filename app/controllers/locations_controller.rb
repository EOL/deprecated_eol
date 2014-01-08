class LocationsController < ApplicationController

  layout 'v2/basic'

  # GET /locations/new
  # GET /locations/new.json
  def new
    @location = Location.new({
      latitude: 41.5267,
      longitude: -70.6631
    })
    @page_title = I18n.t('locations.what_lives_here_question')

    respond_to do |format|
      format.html
      format.json { render json: @location }
    end
  end

  # POST /locations
  # POST /locations.json
  def create
    @location = Location.new(params[:location])
    @location.load_taxa({ language_id: current_language.id })

    respond_to do |format|
      if @location.valid?
        format.html { render action: 'new' }
        format.json { render json: { html: render_to_string(
                                       partial: 'taxa',
                                       formats: [:html]
                                     ),
                                     location: @location
                             },
                             status:   :ok
                    }
      else
        format.html { render action: 'new' }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

end
