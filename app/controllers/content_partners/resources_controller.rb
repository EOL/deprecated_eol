class ContentPartners::ResourcesController < ContentPartnersController

  before_filter :check_authentication

  layout 'v2/partners'

  # GET /content_partners/:content_partner_id/resources
  def index
    @partner = ContentPartner.find(params[:content_partner_id],
                 :include => [ { :resources => :resource_status }, :content_partner_agreements])
    @resources = @partner.resources
    @agreements = @partner.content_partner_agreements
    @new_agreement = @partner.content_partner_agreements.build() if @agreements.blank?
    @partner_contacts = @partner.content_partner_contacts.select{|cpc| cpc.can_be_read_by?(current_user)}
    @new_partner_contact = @partner.content_partner_contacts.build
  end

  # GET /content_partners/:content_partner_id/resources/new
  def new
    @partner = ContentPartner.find(params[:content_partner_id])
    set_new_resource_options
    @resource = @partner.resources.build(:license_id => @licenses.first,
                                         :language_id => current_user.language_id,
                                         :refresh_period_hours => @import_frequencies.first.second )
    access_denied unless current_user.can_create?(@resource)
  end

  # POST /content_partners/:content_partner_id/resources
  def create
    @partner = ContentPartner.find(params[:content_partner_id])
    @resource = @partner.resources.build(params[:resource])
    access_denied unless current_user.can_create?(@resource)
    if @resource.save
      @resource.resource_status = @resource.upload_resource_to_content_master(request.port.to_s)
      # TODO: if we failed to transfer the resource to content master the status will show up in
      # index, but should we provide the user with more information on upload errors here?
      flash[:notice] = I18n.t(:content_partner_resource_create_successful_notice,
                              :resource_status => @resource.status_label)
      redirect_to content_partner_resources_path(@partner)
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
    choose_url_or_file
    @existing_dataset_file_size = @resource.dataset_file_size
    if @resource.update_attributes(params[:resource])
      if upload_required?
        @resource.resource_status = @resource.upload_resource_to_content_master(request.port.to_s)
        # TODO: if we failed to transfer the resource to content master the status will show up in
        # index, but should we provide the user with more information on upload errors here?
      end
      flash[:notice] = I18n.t(:content_partner_resource_update_successful_notice,
                              :resource_status => @resource.status_label)
      redirect_to content_partner_resources_path(@partner)
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
                   :resources => [ :resource_status, :collection, :preview_collection, :license, :language ]})
      @resource = @partner.resources.find(params[:id])
    end
    access_denied unless current_user.can_read?(@resource)
    @page_subheader = I18n.t(:content_partner_resource_show_subheader, :resource_title => Sanitize.clean(@resource.title))
  end

  # GET /content_partners/:content_partner_id/resources/:id/force_harvest
  def force_harvest
    ContentPartner.with_master do
      @partner = ContentPartner.find(params[:content_partner_id], :include => {:resources => :resource_status })
      @resource = @partner.resources.find(params[:id])
    end
    access_denied unless current_user.can_update?(@resource)
    @resource.resource_status = ResourceStatus.force_harvest
    if @resource.save
      flash[:notice] = I18n.t(:content_partner_resource_update_successful_notice,
                              :resource_status => @resource.status_label)
    else
      flash.now[:error] = I18n.t(:content_partner_resource_update_unsuccessful_error)
    end
    redirect_to content_partner_resources_path(@partner)
  end

private
  def choose_url_or_file
    case params[:resource_url_or_file]
    when 'url'
      params[:resource][:dataset] = nil
    when 'upload'
      params[:resource][:accesspoint_url] = ''
    end
  end

  def upload_required?
    @resource &&
    (@resource.accesspoint_url != params[:resource][:accesspoint_url] ||
    @resource.dataset_file_size != @existing_dataset_file_size)
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