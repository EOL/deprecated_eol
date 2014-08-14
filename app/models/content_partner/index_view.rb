class ContentPartner::IndexView
  def initialize(params, cms_url)
    @params = params
    @cms_url = cms_url.html_safe
  end

  def name
    @params[:name] || ""
  end

  def sort_by
    @params[:sort_by] || "partner"
  end

  def page
    @params[:page]
  end

  def page_title
    I18n.t(:content_partners_page_title)
  end

  def page_description
    I18n.t(:content_partners_page_description, more_url: @cms_url)
  end
  
  def sort_options
    [
      [I18n.t(:content_partner_column_header_partner), "partner"],
      [I18n.t(:sort_by_newest_option), "newest"],
      [I18n.t(:sort_by_oldest_option), "oldest"]
    ]
  end
end
