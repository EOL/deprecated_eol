class Admins::ContentPartnersController < AdminsController

  def index
    @page_title = I18n.t(:admin_content_partners_page_title)

    @full_name_like = params[:full_name_like] || ''
    @resource_status_id = params[:resource_status_id]
    @partner_status_id = params[:content_partner_status_id]
    @vetted = params[:vetted]
    @sort_by = params[:sort_by] || 'partner'

    order = case @sort_by
    when 'newest'
      'content_partners.created_at DESC'
    else
      'content_partners.full_name'
    end
    include = [ { :resources => :resource_status }, :content_partner_status, :content_partner_contacts ]
    conditions = "content_partners.full_name LIKE :full_name_like"
    conditions_replacements = {}
    conditions_replacements[:full_name_like] = "%#{@full_name_like}%"
    unless @partner_status_id.blank?
      conditions << " AND content_partners.content_partner_status_id = :partner_status_id"
      conditions_replacements[:partner_status_id] = @partner_status_id
    end
    unless @resource_status_id.blank?
      conditions << " AND resources.resource_status_id = :resource_status_id"
      conditions_replacements[:resource_status_id] = @resource_status_id
    end
    unless @vetted.blank?
      conditions << " AND content_partners.vetted = :vetted"
      conditions_replacements[:vetted] = @vetted
      @vetted = @vetted.to_i
    end
    @partners = ContentPartner.paginate(
                  :page => params[:page],
                  :per_page => 40,
                  :include => include,
                  :conditions => [ conditions, conditions_replacements],
                  :order => order)
    set_filter_options
    set_sort_options
  end

private

  def set_filter_options
    @resource_statuses = @partners.collect{|p| p.resources.collect{|r| r.resource_status}}.flatten.uniq.compact
    @partner_statuses  = @partners.collect{|p| p.content_partner_status}.flatten.uniq.compact
    @vetted_options    = [[I18n.t(:option_please_select), ""],
                          [I18n.t(:content_partner_filter_option_vetted_yes), 1],
                          [I18n.t(:content_partner_filter_option_vetted_no), 0]]
  end

  def set_sort_options
    @sort_by_options   = [[I18n.t(:content_partner_column_header_partner), 'partner'],
                          [I18n.t(:sort_by_newest_option), 'newest'],
                          [I18n.t(:sort_by_oldest_option), 'oldest']]
  end

end