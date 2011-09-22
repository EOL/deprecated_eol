class ContentPartners::Resources::HarvestEventsController < ContentPartners::ResourcesController

  # GET /content_partners/:content_partner_id/resources/:resource_id/harvest_events
  def index
    @partner = ContentPartner.find(params[:content_partner_id], :include => [ { :resources => :resource_status } ])
    @resource = @partner.resources.find(params[:resource_id])
    @harvest_events = @resource.harvest_events.paginate(:page => params[:page], :per_page => 50, :order => "id DESC")
    @page_subheader = I18n.t(:content_partner_resource_harvest_events_for_resource_subheader, :resource_title => Sanitize.clean(@resource.title))
    @head_title = "#{Sanitize.clean(@partner.name)} - #{@page_subheader}"
  end


end