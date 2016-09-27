class ContentPartners::ResourcesController < ContentPartnersController

  before_filter :check_authentication
  before_filter :restrict_to_admins, only: [:destroy]

  layout 'partners'

  # GET /content_partners/:content_partner_id/resources
  def index
    @partner = ContentPartner.find(params[:content_partner_id],
                 include: [ { resources: :resource_status }, :content_partner_agreements, :content_partner_contacts])
    return access_denied unless current_user.can_update?(@partner)
    return if !current_user.is_admin? && redirect_if_terms_not_accepted
    @resources = @partner.resources
    @partner_contacts = @partner.content_partner_contacts.select{|cpc| cpc.can_be_read_by?(current_user)}
    @new_partner_contact = @partner.content_partner_contacts.build
  end

  # GET /content_partners/:content_partner_id/resources/new
  def new
    @partner = ContentPartner.find(params[:content_partner_id])
    set_new_resource_options
    @resource = @partner.resources.build(license_id: @licenses.first.id,
                                         language_id: current_language.id,
                                         refresh_period_hours: @import_frequencies.first.second )
    access_denied unless current_user.can_create?(@resource)
  end

  # POST /content_partners/:content_partner_id/resources
  def create
    @partner = ContentPartner.find(params[:content_partner_id])
    @resource = @partner.resources.build(params[:resource])
    access_denied unless current_user.can_create?(@resource)
    if @resource.save
      Notifier.content_partner_resource_created(@partner, @resource, current_user).deliver
      flash[:notice] = I18n.t(:content_partner_resource_create_successful_notice,
                              resource_status: @resource.status_label) unless flash[:error]
      redirect_to content_partner_resources_path(@partner), status: :moved_permanently
    else
      set_new_resource_options
      flash.now[:error] = I18n.t(:content_partner_resource_create_unsuccessful_error)
      render :new
    end
    @resource.update_attributes(resource_status: ResourceStatus.uploading)
    enqueue_job(current_user.id, @resource.id)
  end

  # GET /content_partners/:content_partner_id/resources/:id/edit
  def edit
    @partner = ContentPartner.find(params[:content_partner_id], include: [:resources])
    set_resource_options
    @resource = @partner.resources.find(params[:id])
    @page_subheader = I18n.t(:content_partner_resource_edit_subheader)
  end

  # PUT /content_partners/:content_partner_id/resources/:id
  def update
    ContentPartner.with_master do
      @partner = ContentPartner.find(params[:content_partner_id], include: {resources: :resource_status })
      @resource = @partner.resources.find(params[:id])
    end
    access_denied unless current_user.can_update?(@resource)
    if params[:commit_update_settings_only]
      upload_required = false
    else
      choose_url_or_file
      @existing_dataset_file_size = @resource.dataset_file_size
      # we need to check the accesspoint URL before saving the updated resource
      upload_required = (@resource.accesspoint_url != params[:resource][:accesspoint_url] || !params[:resource][:dataset].blank?)
    end
    if @resource.update_attributes(params[:resource])
      if upload_required
        @resource.update_attributes(resource_status: ResourceStatus.uploading)
        enqueue_job(current_user.id, params[:id])
      end
      if params[:resource][:auto_publish].to_i == 0
        @resource.delete_resource_contributions_file
      else
        @resource.save_resource_contributions
      end
      flash[:notice] = I18n.t(:content_partner_resource_update_successful_notice,
                              resource_status: @resource.status_label) unless flash[:error]
      store_location(params[:return_to]) unless params[:return_to].blank?
      redirect_back_or_default content_partner_resource_path(@partner, @resource)
    else
      set_resource_options
      flash.now[:error] = I18n.t(:content_partner_resource_update_unsuccessful_error)
      render :edit
    end
  end

  # GET /content_partners/:content_partner_id/resources/:id
  def show
    ContentPartner.with_master do
      if params[:content_partner_id]
        @partner = ContentPartner.find(params[:content_partner_id], include: {
                     resources: [ :resource_status, :collection, :preview_collection, :license, :language, :harvest_events, :hierarchy, :dwc_hierarchy ]})
        @resource = @partner.resources.find(params[:id])
      else
        @resource = Resource.find(params[:id])
        @partner = @resource.content_partner
      end
    end
    @page_subheader = I18n.t(:content_partner_resource_show_subheader, resource_title: Sanitize.clean(@resource.title))
    @meta_data = { title: I18n.t(:content_partner_resource_page_title, :content_partner_name => @partner.full_name, :resource_name => @resource.title) }
  end

  # GET /content_partners/:content_partner_id/resources/:id/harvest_requested
  # POST /content_partners/:content_partner_id/resources/:id/harvest_requested
  def harvest_requested
    ContentPartner.with_master do
      @partner = ContentPartner.find(params[:content_partner_id], include: {resources: :resource_status })
      @resource = @partner.resources.find(params[:id])
    end
    access_denied unless current_user.can_update?(@resource)
    if @resource.status_can_be_changed_to?(ResourceStatus.harvest_tonight)
      @resource.resource_status = ResourceStatus.harvest_tonight
      if @resource.save
        flash[:notice] = I18n.t(:content_partner_resource_status_update_successful_notice,
                                resource_status: @resource.status_label, resource_title: @resource.title)
      else
        flash.now[:error] = I18n.t(:content_partner_resource_status_update_unsuccessful_error,
                                   resource_status: @resource.status_label, resource_title: @resource.title)
      end
    else
      flash[:error] = I18n.t(:content_partner_resource_status_update_illegal_transition_error,
                             resource_title: @resource.title, current_resource_status: @resource.status_label,
                             requested_resource_status: Resource.harvest_tonight.label)
    end
    store_location request.referer unless request.referer.blank?
    redirect_back_or_default content_partner_resources_path(@partner)
  end

  # NOTE: Errr... Long story about why this sets it to "harvest requested" when
  # you're removing the request, but this is *actually* undoing a "harvest
  # tonight", and I didn't want to rename it everywhere...
  def remove_harvest_request
    ContentPartner.with_master do
      @partner = ContentPartner.find(params[:content_partner_id], include: {resources: :resource_status })
      @resource = @partner.resources.find(params[:id])
    end
    access_denied unless current_user.can_update?(@resource)
    @resource.resource_status = ResourceStatus.harvest_requested
    if @resource.save
      flash[:notice] = I18n.t(:content_partner_resource_status_update_successful_notice,
                              resource_status: @resource.status_label, resource_title: @resource.title)
    else
      flash.now[:error] = I18n.t(:content_partner_resource_status_update_unsuccessful_error,
                                 resource_status: @resource.status_label, resource_title: @resource.title)
    end
    store_location request.referer unless request.referer.blank?
    redirect_back_or_default content_partner_resources_path(@partner)
  end

  def destroy
    partner = ContentPartner.find(params[:content_partner_id], include: [:resources])
    resource = partner.resources.find(params[:id])
    resource_title = resource.title
    if resource
      resource.update_attributes(resource_status: ResourceStatus.obsolete)
      ResourceDestroyer.enqueue(resource.id)
      redirect_to content_partner_path(partner)
      flash[:notice] = I18n.t(:content_partner_resource_will_be_deleted, resource_title: resource_title)
    end
  end

private

  def enqueue_job(user_id, resource_id)
    EOL.log("BACKGROUND: resource upload for ID: #{@resource.id}")
    Resque.enqueue(ResourceValidation, user_id, resource_id,
      EOL::Server.ip_address)
  end

  def redirect_if_terms_not_accepted
    @current_agreement = @partner.agreement
    if @current_agreement.blank?
      redirect_to new_content_partner_agreement_path(@partner), status: :moved_permanently
    elsif !@current_agreement.is_accepted?
      redirect_to edit_content_partner_agreement_path(@partner, @current_agreement), status: :moved_permanently
    end
  end

  def choose_url_or_file
    case params[:resource_url_or_file]
    when 'url'
      params[:resource][:dataset] = nil
    when 'upload'
      params[:resource][:accesspoint_url] = ''
    end
  end

  def set_resource_options
    # the .order(:source_url).reverse makes for a better display, and default
    # license since the first in the list will show first in the drop-down menu
    @licenses = License.show_to_content_partners.order(:source_url).reverse
    @languages = Language.find_active
    @import_frequencies = [ [ I18n.t(:import_once), 0 ],
                            [ I18n.t(:weekly), 7 * 24 ],
                            [ I18n.t(:monthly), 30 * 24 ],
                            [ I18n.t(:bi_monthly), 60 * 24 ],
                            [ I18n.t(:quarterly), 91 * 24 ] ]
  end

  def set_new_resource_options
    set_resource_options
    @page_subheader = I18n.t(:content_partner_resource_new_subheader)
  end
end
