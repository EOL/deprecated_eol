class DataObjectsController < ApplicationController

  layout proc { |c| c.request.xhr? ? false : "main" }

  before_filter :set_data_object

  make_resourceful do
    actions :show

    before :show do
      @data_object ||= current_object # Because we use a partial that assumes this is defined 
    end
  end

  # GET /data_objects/1/attribution
  def attribution
    render :partial => 'attribution', :locals => { :data_object => current_object }, :layout => @layout
  end

  # GET /data_objects/1/curation
  # GET /data_objects/1/curation.js
  #
  # UI for curating a data object
  #
  # This is a GET, so there's no real reason to check to see 
  # whether or not the current_user can_curate the object - 
  # we leave that to the #curate method
  #
  def curation
  end

  # PUT /data_objects/1/curate
  def curate
    @data_object.curate!(params[:curator_activity_id]) if current_user.can_curate?(@data_object)
    
    respond_to do |format|
      format.html {redirect_to request.referer ? :back : '/'}
      format.js {render :nothing => true}
    end
  end

protected

  def set_data_object
    @data_object ||= DataObject.find params[:id]
  end

end
