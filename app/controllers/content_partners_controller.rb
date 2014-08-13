# EXEMPLAR
#
# You should:
# * follow this pattern (of thin controller methods) as closely as possible.
#   Public methods should follow REST/CRUD, everything else should be kept
#   private.
# * Try to keep all of your access control here in the controller.
# * Move as much logic as you can to the models.

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

  def load_content_partner
    @partner = ContentPartner::AsUnassisted.find(
      params[:id],
      include: [{ resources: :collection }, :content_partner_contacts]
    )
    access_denied unless current_user.can_read?(@partner)
    @partner_collections = @partner.resources.map { |r| r.collection }.compact
    @rel_canonical_href = content_partner_url(@partner)
  end

  def save_content_partner
    if @partner.save
      upload_logo(@partner) unless params[:content_partner][:logo].blank?
      flash[:notice] = I18n.t(:content_partner_update_successful_notice)
      # If they have no resources, encourage them to add one:
      path = @partner.resources.empty? ?
        content_partner_resources_path(@partner) : @partner
      redirect_to path, status: :moved_permanently
    else
      flash.now[:error] = I18n.t(:content_partner_update_unsuccessful_error)
      false
    end
  end

  def build_content_partner
    # Use post to pass in user_id for new content partner otherwise you'll
    # get access denied
    @partner ||= ContentPartner::AsUnassisted.new(params[:content_partner])
    @partner.attributes = params[:content_partner]
    set_page_titles
  end

  def load_content_partners
    @name    = params[:name] || ''
    @sort_by = params[:sort_by] || 'partner'
    @page    = params[:page]

    # TODO: Select is being ignored in the following. Appears to be when
    # conditions added. Find a solution.
    @partners = ContentPartner::Paginate.new(@page, @name, @sort_by).run
    set_sort_options
    @page_title = I18n.t(:content_partners_page_title)
    @page_description = I18n.t(:content_partners_page_description,
                               more_url: cms_page_path('partners')).html_safe
    set_canonical_urls(paginated: @partners, url_method: :content_partners_url)
  end

  def content_partners_layout
    ContentPartner
    case action_name
    when 'index', 'new'
      'basic'
    else
      'partners'
    end
  end

  def set_page_titles
    @page_title = I18n.t(:content_partners_page_title)
    @page_subtitle = I18n.t(:content_partner_new_page_subheader)
  end

  def set_sort_options
    @sort_by_options   = [[I18n.t(:content_partner_column_header_partner),
                            'partner'],
                          [I18n.t(:sort_by_newest_option), 'newest'],
                          [I18n.t(:sort_by_oldest_option), 'oldest']]
  end

  def scoped_variables_for_translations
    @scoped_variables_for_translations ||= super.dup.merge({
      partner_name: @partner ? @partner.name : nil,
      partner_description: (@partner && description = @partner.description) ?
        description : I18n.t(:content_partner_default_description)
    }).freeze
  end

  def meta_open_graph_image_url
    @meta_open_graph_image_url ||=  @partner ?
      view_context.image_tag(
        @partner.logo_url('large', $SINGLE_DOMAIN_CONTENT_SERVER)
      ) : nil
  end

end
