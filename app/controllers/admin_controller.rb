class AdminController < ApplicationController

  layout 'deprecated/left_menu'

  before_filter :check_authentication
  before_filter :set_no_cache
  before_filter :set_layout_variables
  before_filter :restrict_to_admins

  def index
    current_harvet
  end

private

  def set_no_cache
   @no_cache = true
  end

  def set_layout_variables
    @page_title = I18n.t("eol_administration_console")
    @navigation_partial = '/admin/navigation'
  end
  
  def current_harvet
    @current_harvesting = HarvestEvent.where("completed_at IS NULL").first
    if @current_harvesting
      @harvesting_resource = Resource.find(@current_harvesting.resource_id)
    end
  end

end
