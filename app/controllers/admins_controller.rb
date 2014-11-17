class AdminsController < ApplicationController

  layout 'admin'

  before_filter :check_authentication
  before_filter :restrict_to_admins

  # TODO - this shouldn't be a show, it should be an index, right?
  def show
    @page_title = I18n.t(:admin_page_title)
    current_harvest
  end

  def recount_collection_items
    CollectionItem.counter_culture_fix_counts
    flash[:notice] = I18n.t(:recount_collection_items_done)
    redirect_to admin_path
  end
  
  # show running harvesting
  def current_harvest
    @current_harvesting = HarvestEvent.where("completed_at IS NULL").first
    if @current_harvesting
      @harvesting_resource = Resource.find(@current_harvesting.resource_id)
    end
  end

end
