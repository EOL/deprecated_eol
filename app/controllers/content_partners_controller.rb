class ContentPartnersController < ApplicationController

  before_filter :check_authentication, :except => [:show, :index]

  layout :content_partners_layout

  # GET /content_partners
  def index
    @name = params[:name] || ''
    @sort_by = params[:sort_by] || 'partner'

    order = case @sort_by
    when 'newest'
      'content_partners.created_at DESC'
    when 'oldest'
      'content_partners.created_at'
    else
      'content_partners.full_name'
    end
    # TODO: Select is being ignored in the following. Appears to be when conditions added. Find a solution.
    include = [ { :resources => [ :resource_status ] }, :content_partner_status, :content_partner_contacts ]
    select = 'content_partners.id, content_partners.full_name, content_partners.display_name, content_partners.description,
              content_partners.homepage, content_partners.logo_cache_url, content_partners.logo_file_name,
              content_partners.logo_content_type, content_partners.logo_file_size, content_partners.created_at,
              resources.id, resources.collection_id, resources.resource_status_id,
              resource_statuses.*, harvest_events.*'
    conditions = "content_partners.public = 1 AND content_partners.full_name LIKE :name"
    conditions_replacements = {}
    conditions_replacements[:name] = "%#{@name}%"
    @partners = ContentPartner.paginate(
                  :page => params[:page],
                  :per_page => 10,
                  :select => select,
                  :include => include,
                  :conditions => [ conditions, conditions_replacements],
                  :order => order)
    set_sort_options
    @page_title = I18n.t(:content_partners_page_title)
    @page_description = I18n.t(:content_partners_page_description, :more_url => cms_page_path('partners')).html_safe
    # TODO - test if this works!  I'm not passing in a :for ... which is weird.
    set_canonical_urls(:paginated => @partners, :url_method => :content_partner_statistics_url)
  end

  # GET /content_partners/new
  # POST /content_partners/new
  def new
    # Use post to pass in user_id for new content partner otherwise you'll get access denied
    @partner = ContentPartner.new(params[:content_partner])
    access_denied unless current_user.can_create?(@partner)
    set_new_partner_options
  end

  # POST /content_partners
  def create
    @partner = ContentPartner.new(params[:content_partner])
    access_denied unless current_user.can_create?(@partner)
    if @partner.save
      upload_logo(@partner) unless params[:content_partner][:logo].blank?
      Notifier.content_partner_created(@partner, current_user).deliver
      flash[:notice] = I18n.t(:content_partner_create_successful_notice)
      redirect_to content_partner_resources_path(@partner), :status => :moved_permanently
    else
      set_new_partner_options
      flash.now[:error] = I18n.t(:content_partner_create_unsuccessful_error)
      render :new
    end
  end

  # GET /content_partners/:id
  def show
    @partner = ContentPartner.find(params[:id], :include => [{ :resources => :collection }, :content_partner_contacts ])
    access_denied unless current_user.can_read?(@partner)
    @partner_collections = @partner.resources.collect{|r| r.collection}.compact
    @rel_canonical_href = content_partner_url(@partner)
  end

  # GET /content_partners/:id/edit
  def edit
    @partner = ContentPartner.find(params[:id])
    access_denied unless current_user.can_update?(@partner)
  end

  # PUT /content_partners/:id
  def update
    @partner = ContentPartner.find(params[:id])
    access_denied unless current_user.can_update?(@partner)
    if @partner.update_attributes(params[:content_partner])
      EOL::GlobalStatistics.clear('content_partners') # Needs to be re-calculated.
      upload_logo(@partner) unless params[:content_partner][:logo].blank?
      flash[:notice] = I18n.t(:content_partner_update_successful_notice)
      redirect_to @partner, :status => :moved_permanently
    else
      flash.now[:error] = I18n.t(:content_partner_update_unsuccessful_error)
      render :edit
    end
  end

protected
  def scoped_variables_for_translations
    @scoped_variables_for_translations ||= super.dup.merge({
      :partner_name => @partner ? @partner.name : nil,
      :partner_description => (@partner && description = @partner.description) ?
        description : I18n.t(:content_partner_default_description)
    }).freeze
  end

  def meta_open_graph_image_url
    @meta_open_graph_image_url ||=  @partner ?
      view_context.image_tag(@partner.logo_url('large', $SINGLE_DOMAIN_CONTENT_SERVER)) : nil
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

  def set_sort_options
    @sort_by_options   = [[I18n.t(:content_partner_column_header_partner), 'partner'],
                          [I18n.t(:sort_by_newest_option), 'newest'],
                          [I18n.t(:sort_by_oldest_option), 'oldest']]
  end

end
