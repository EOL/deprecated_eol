class HarvestEventsController < ApplicationController

  before_filter :find_resource
  before_filter :this_resource_must_belong_to_agent, :except => [:index, :create, :new]
  before_filter :agent_login_required, :agent_must_be_agreeable, :unless => :is_user_admin?
  before_filter :set_layout_variables
  layout :choose_layout

  def index
    @page_title = I18n.t("content_partner_reports")
    @page_header = 'Edit Resource' # This is weird, but the separate layouts use separate variable names...
    page = params[:page] || 1
    @harvest_events = HarvestEvent.paginate_by_resource_id(@resource.id, :page => page, :order => "id desc")
  end

  def update
    @harvest_event = HarvestEvent.find(params[:id])
    @resource.publish @harvest_event
    redirect_to :back, :status => :moved_permanently
  end

protected
  def find_resource
    resource_id = params.key?(:resource_id) ? params[:resource_id] : nil
    @resource = resource_id ? Resource.find(resource_id) : nil
  end

  def choose_layout
    current_user.is_admin? ? 'left_menu' : 'content_partner'
  end

  def this_resource_must_belong_to_agent
    resource_must_belong_to_agent(find_resource)
  end

  def is_user_admin?
    current_user.is_admin?
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
