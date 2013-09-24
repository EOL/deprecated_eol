class ContentPartners::ResourcesController < ContentPartnersController

  before_filter :check_authentication

  layout 'v2/partners'

  # GET /content_partners/:content_partner_id/resources
  def index
    @partner = ContentPartner.find(params[:content_partner_id],
                 :include => [ { :resources => :resource_status }, :content_partner_agreements, :content_partner_contacts])
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
    @resource = @partner.resources.build(:license_id => @licenses.first.id,
                                         :language_id => current_language.id,
                                         :refresh_period_hours => @import_frequencies.first.second )
    access_denied unless current_user.can_create?(@resource)
  end

  # POST /content_partners/:content_partner_id/resources
  def create
    @partner = ContentPartner.find(params[:content_partner_id])
    @resource = @partner.resources.build(params[:resource])
    access_denied unless current_user.can_create?(@resource)
    if @resource.save
      @resource.upload_resource_to_content_master!(request.port.to_s)
      unless [ResourceStatus.uploaded.id, ResourceStatus.validated.id].include?(@resource.resource_status_id)
        if @resource.resource_status_id = ResourceStatus.validation_failed.id
          flash[:error] = I18n.t(:content_partner_resource_validation_unsuccessful_error)
        else
          flash[:error] = I18n.t(:content_partner_resource_upload_unsuccessful_error, :resource_status => @resource.status_label)
        end
      end
      Notifier.content_partner_resource_created(@partner, @resource, current_user).deliver
      flash[:notice] = I18n.t(:content_partner_resource_create_successful_notice,
                              :resource_status => @resource.status_label) unless flash[:error]
      redirect_to content_partner_resources_path(@partner), :status => :moved_permanently
    else
      set_new_resource_options
      flash.now[:error] = I18n.t(:content_partner_resource_create_unsuccessful_error)
      render :new
    end
  end

  # GET /content_partners/:content_partner_id/resources/:id/edit
  def edit
    @partner = ContentPartner.find(params[:content_partner_id], :include => [:resources])
    set_resource_options
    @resource = @partner.resources.find(params[:id])
    @page_subheader = I18n.t(:content_partner_resource_edit_subheader)
  end

  # PUT /content_partners/:content_partner_id/resources/:id
  def update
    ContentPartner.with_master do
      @partner = ContentPartner.find(params[:content_partner_id], :include => {:resources => :resource_status })
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
        @resource.upload_resource_to_content_master!(request.port.to_s)
        unless [ResourceStatus.uploaded.id, ResourceStatus.validated.id].include?(@resource.resource_status_id)
          if @resource.resource_status_id = ResourceStatus.validation_failed.id
            flash[:error] = I18n.t(:content_partner_resource_validation_unsuccessful_error)
          else
            flash[:error] = I18n.t(:content_partner_resource_upload_unsuccessful_error, :resource_status => @resource.status_label)
          end
        end
      end
      flash[:notice] = I18n.t(:content_partner_resource_update_successful_notice,
                              :resource_status => @resource.status_label) unless flash[:error]
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
      @partner = ContentPartner.find(params[:content_partner_id], :include => {
                   :resources => [ :resource_status, :collection, :preview_collection, :license, :language, :harvest_events, :hierarchy, :dwc_hierarchy ]})
      @resource = @partner.resources.find(params[:id])
    end
    access_denied unless current_user.can_read?(@resource)
    @page_subheader = I18n.t(:content_partner_resource_show_subheader, :resource_title => Sanitize.clean(@resource.title))
  end

  # GET /content_partners/:content_partner_id/resources/:id/force_harvest
  # POST /content_partners/:content_partner_id/resources/:id/force_harvest
  def force_harvest
    ContentPartner.with_master do
      @partner = ContentPartner.find(params[:content_partner_id], :include => {:resources => :resource_status })
      @resource = @partner.resources.find(params[:id])
    end
    access_denied unless current_user.can_update?(@resource)
    if @resource.resource_status.blank? || @resource.resource_status == ResourceStatus.being_processed
      flash[:error] = I18n.t(:content_partner_resource_status_update_illegal_transition_error,
                             :resource_title => @resource.title, :current_resource_status => @resource.status_label,
                             :requested_resource_status => Resource.force_harvest.label)
    else
      @resource.resource_status = ResourceStatus.force_harvest
      if @resource.save
        flash[:notice] = I18n.t(:content_partner_resource_status_update_successful_notice,
                                :resource_status => @resource.status_label, :resource_title => @resource.title)
      else
        flash.now[:error] = I18n.t(:content_partner_resource_status_update_unsuccessful_error,
                                   :resource_status => @resource.status_label, :resource_title => @resource.title)
      end
    end
    store_location request.referer unless request.referer.blank?
    redirect_back_or_default content_partner_resources_path(@partner)
  end

private

  def redirect_if_terms_not_accepted
    @current_agreement = @partner.agreement
    if @current_agreement.blank?
      redirect_to new_content_partner_agreement_path(@partner), :status => :moved_permanently
    elsif !@current_agreement.is_accepted?
      redirect_to edit_content_partner_agreement_path(@partner, @current_agreement), :status => :moved_permanently
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
    @licenses = License.find_all_by_show_to_content_partners(true)
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
