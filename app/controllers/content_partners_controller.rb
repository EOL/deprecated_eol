class ContentPartnersController < ApplicationController

  before_filter :check_authentication, :except => [:show]

  layout :content_partners_layout

  # GET /content_partners
  def index
    # WIP
    @partners = ContentPartner.all
    @page_title = I18n.t(:content_partners_page_title)
    @partner_search_string = params[:partner_search_string] || ''
  end

  # GET /content_partners/new
  def new
    @partner = ContentPartner.new
    access_denied unless current_user.can_create?(@partner)
    set_new_partner_options
  end

  def create
    @partner = ContentPartner.new(params[:content_partner])
    access_denied unless current_user.can_create?(@partner)
    if @partner.save
      upload_logo(@partner) unless params[:content_partner][:logo].blank?
      flash[:notice] = I18n.t(:content_partner_create_successful_notice)
      redirect_to @partner
    else
      set_new_partner_options
      flash.now[:error] = I18n.t(:content_partner_create_unsuccessful_error)
      render :new
    end
  end

  # GET /content_partners/:id
  def show
    @partner = ContentPartner.find(params[:id])
    @partner_contacts = @partner.content_partner_contacts.select{|cpc| cpc.can_be_read_by?(current_user)}
    @new_partner_contact = @partner.content_partner_contacts.build
    @head_title = @partner.name
  end

  # GET /content_partners/:id/edit
  def edit
    @partner = ContentPartner.find(params[:id])
    access_denied unless current_user.can_update?(@partner)
    @head_title = @partner.name
  end

  # PUT /content_partners/:id
  def update
    @partner = ContentPartner.find(params[:id])
    access_denied unless current_user.can_update?(@partner)
    if @partner.update_attributes(params[:content_partner])
      upload_logo(@partner) unless params[:content_partner][:logo].blank?
      flash[:notice] = I18n.t(:content_partner_update_successful_notice)
      redirect_to @partner
    else
      flash.now[:error] = I18n.t(:content_partner_update_unsuccessful_error)
      render :edit
    end
  end

private

  def content_partners_layout
    case action_name
    when 'index', 'new'
      'v2/basic'
    else
      'v2/partners'
    end
  end

  def set_new_partner_options
    @page_title = I18n.t(:content_partners_page_title)
    @page_subtitle = I18n.t(:content_partner_new_page_subheader)
  end

end