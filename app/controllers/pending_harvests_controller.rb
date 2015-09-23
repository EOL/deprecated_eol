class PendingHarvestsController < ApplicationController

  before_filter :restrict_to_admins_and_master_curators
  before_filter :set_page_title

  def index
    @pending_harvests = Resource.ready.paginate(page: params[:page], order: 'resources.position', per_page: 500)
    respond_to do |format|
      format.html
    end
  end

  def set_page_title
    @page_title = I18n.t(:pending_harvests_title)
  end

  def sort
    last_position = nil
    p_harvests = Resource.ready
    @pending_harvest = p_harvests.find(params['moved_id'].sub('pending_harvest_', ''))
    if params['pending_harvests']
      position_in_results = params['pending_harvests'].index(params['moved_id'])
      if position_in_results == params['pending_harvests'].length - 1
        previous_element = Resource.find(params['pending_harvests'][-2].sub('pending_harvest_', ''))
        @pending_harvest.position = previous_element.position + 1
        Resource.update_all('position = position + 1', "position >= #{previous_element.position + 1}")
        @pending_harvest.save
      else
        next_element = Resource.find(params['pending_harvests'][position_in_results + 1].sub('pending_harvest_', ''))
        @pending_harvest.position = next_element.position
        Resource.update_all('position = position + 1', "position >= #{next_element.position}")
        @pending_harvest.save
      end
    elsif params['to'] == 'top'
      @to = :top
      @pending_harvest.move_to_top
    elsif params['to'] == 'bottom'
      @to = :bottom
      @pending_harvest.move_to_bottom
    else
      raise(InvalidArgumentsError)
    end
    respond_to do |format|
      format.js { }
    end
  end

  def pause_harvesting
    Resource.update_all(pause: true)
    head :ok
  end

  def resume_harvesting
    Resource.update_all(pause: false)
    head :ok
  end

end
