class ContentPartners::Resources::HarvestEventsController < ContentPartners::ResourcesController

  # GET /content_partners/:content_partner_id/resources/:resource_id/harvest_events
  def index
    @partner = ContentPartner.find(params[:content_partner_id], include: [ { resources: :resource_status } ])
    @resource = @partner.resources.find(params[:resource_id])
    @harvest_events = @resource.harvest_events.paginate(page: params[:page], per_page: 50, order: "id DESC")
    @page_subheader = I18n.t(:content_partner_resource_harvest_events_for_resource_subheader, resource_title: Sanitize.clean(@resource.title))
  end

  # PUT /content_partners/:content_partner_id/resources/:resource_id/harvest_events/:id
  def update
    access_denied unless current_user.is_admin?
    HarvestEvent.with_master do
      @harvest_event = HarvestEvent.find(params[:id], include: { resource: :content_partner })
    end
    if @harvest_event.update_attributes(params[:harvest_event])
      flash[:notice] = I18n.t(:content_partner_resource_harvest_event_update_successful_notice,
                              resource_title: @harvest_event.resource.title)
    else
      flash[:error] = I18n.t(:content_partner_resource_harvest_event_update_unsuccessful_error,
                             resource_title: @harvest_event.resource.title)
      flash[:error] << " #{@harvest_event.errors.full_messages.join('; ')}." if @harvest_event.errors.any?

    end
    store_location request.referer unless request.referer.blank?
    store_location params[:return_to] unless params[:return_to].blank?
    redirect_back_or_default content_partner_resource_path(@harvest_event.resource.content_partner, @harvest_event.resource)
  end

end
