class ContentPartners::ResourcesController < ContentPartnersController

  before_filter :check_authentication

  layout 'v2/partners'

  # GET /content_partners/:content_partner_id/resources
  def index
    @partner = ContentPartner.find(params[:content_partner_id])
    @resources = @partner.resources
    @page_subheader = I18n.t(:content_partner_resources)
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
      @resource.resource_status = @resource.upload_resource_to_content_master('http://' + $IP_ADDRESS_OF_SERVER + ":" + request.port.to_s)
      @resource.save # TODO: Do we need a check here to see if resource was uploaded?
      flash[:notice] = I18n.t(:content_partner_resource_create_successful_notice)
      redirect_to content_partner_resources_path(@partner)
    else
      set_new_resource_options
      flash.now[:error] = I18n.t(:content_partner_resource_create_unsuccessful_error)
      render :new
    end
  end

  # GET /content_partners/:content_partner_id/resources/:id/edit
  def edit
    @partner = ContentPartner.find(params[:content_partner_id])
    set_resource_options
    @resource = @partner.resources.find(params[:id])
    @page_subheader = I18n.t(:content_partner_resource_edit_subheader)
  end

  # PUT /content_partners/:content_partner_id/resources/:id
  def update

  end

private
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