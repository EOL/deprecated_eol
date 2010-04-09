class HarvestEventsController < ApplicationController

  before_filter :find_resource
  before_filter :agent_login_required, :resource_must_belong_to_agent, :agent_must_be_agreeable, :unless => :is_user_admin?
  layout :choose_layout

  def index
    @page_title = 'Content Partner Reports'
    @page_header = 'Edit Resource' # This is weird, but the separate layouts use separate variable names...
    page = params[:page] || 1
    @harvest_events = HarvestEvent.paginate_by_resource_id(@resource.id, :page => page, :order => "id desc")
  end
  
  def update
    @harvest_event = HarvestEvent.find(params[:id])
    @resource.publish @harvest_event
    redirect_to :back
  end

protected
  def find_resource
    resource_id = params.key?(:resource_id) ? params[:resource_id] : nil
    @resource = resource_id ? Resource.find(resource_id) : nil
  end

  def choose_layout
    current_user.is_admin? ? 'admin' : 'content_partner'
  end

end
