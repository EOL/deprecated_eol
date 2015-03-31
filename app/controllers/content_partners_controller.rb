# encoding: utf-8
# EXEMPLAR

# ContentPartnersController manages content parter related views
class ContentPartnersController < ApplicationController
  before_filter :check_authentication, except: [:show, :index]

  layout :content_partners_layout

  def index
    load_content_partners
  end

  def show
    load_content_partner
  end

  def new
    build_content_partner
  end

  def create
    build_content_partner
    access_denied unless current_user.can_create?(@partner)
    save_content_partner || render(:new)
  end

  def edit
    load_content_partner
    access_denied unless current_user.can_update?(@partner)
  end

  def update
    load_content_partner
    build_content_partner
    access_denied unless current_user.can_update?(@partner)
    save_content_partner || render(:edit)
  end

  private

  def load_content_partners
    index_meta = ContentPartner::IndexMeta.new(params,
                                               cms_page_path("partners"))
    @page_meta = PageMeta.new(index_meta)
    @partners = ContentPartner::Pagination.paginate(index_meta)
    set_canonical_urls(paginated: @partners, url_method: :content_partners_url)
  end

  def load_content_partner
    @partner = ContentPartner.find(
      params[:id],
      include: [{ resources: :collection }, :content_partner_contacts]
    )
    access_denied unless current_user.can_read?(@partner)
    @rel_canonical_href = content_partner_url(@partner)
  end

  def save_content_partner
    if @partner.save
      upload_logo(
        @partner,
        name: params[:content_partner][:logo].original_filename
      ) unless params[:content_partner][:logo].blank?
      flash[:notice] = I18n.t(:content_partner_update_successful_notice)
      redirect_to partner_conditional_path, status: :moved_permanently
    else
      flash.now[:error] = I18n.t(:content_partner_update_unsuccessful_error)
      false
    end
  end

  def partner_conditional_path
    if @partner.resources.empty?
      content_partner_resources_path(@partner)
    else
      @partner
    end
  end

  def build_content_partner
    cp = current_user.is_admin? ? ContentPartner : ContentPartner::AsUnassisted
    @partner ||= cp.new(params[:content_partner])
    @partner.attributes = params[:content_partner]
    @partner.user ||= current_user
    meta = ContentPartner::Meta.new
    @page_meta = PageMeta.new(meta)
  end

  def content_partners_layout
    %w(index new).include?(action_name) ? "basic" : "partners"
  end

  def scoped_variables_for_translations
    @scoped_variables_for_translations ||= super.dup.merge(
      partner_name: @partner ? @partner.name : nil,
      partner_description: partner_description
    ).freeze
  end

  def partner_description
    description = @partner && @partner.description
    description || I18n.t(:content_partner_default_description)
  end

  def meta_open_graph_image_url
    @meta_open_graph_image_url ||= calc_meta_open_graph_image_url
  end

  def calc_meta_open_graph_image_url
    @partner &&= view_context.image_tag(@partner.logo_url(linked?: true))
  end
end
