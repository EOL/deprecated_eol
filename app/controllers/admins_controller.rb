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
   @harvest_log = HarvestProcessLog.harvesting.last
   if @harvest_log && ! @harvest_log.complete?
     @harvest_resource = HarvestEvent.last_incomplete_resource
   end
  end

end
