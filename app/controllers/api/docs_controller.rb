class Api::DocsController < ApiController
  layout 'basic'
  skip_before_filter :handle_key, :set_default_format_to_xml
  before_filter :set_locale, :set_navigation_menu

  def index
    @page_title = I18n.t(:eol_api)
    render :index
  end

  def ping
    @page_title = I18n.t(:eol_api_ping)
  end

  def pages
    @page_title = I18n.t(:eol_api_pages)
  end

  def search
    @page_title = I18n.t(:eol_api_search)
  end

  def data_objects
    @page_title = I18n.t(:eol_api_data_objects)
  end

  def hierarchy_entries
    @page_title = I18n.t(:eol_api_hierarchy_entries)
  end

  def hierarchy_entries_descendants
    @page_title = I18n.t(:eol_api_hierarchy_entries_descendants)
  end

  def provider_hierarchies
    @page_title = I18n.t(:eol_api_provider_hierarchies)
  end

  def hierarchies
    @page_title = I18n.t(:eol_api_hierarchies)
  end

  def search_by_provider
    @page_title = I18n.t(:eol_api_search_by_provider)
  end

  def collections
    @page_title = I18n.t(:eol_api_collections)
  end

  private

  def default_render
    render template: 'api/docs/method_documentation'
  end

  def set_navigation_menu
    api_overview = ContentPage.find_by_page_name('api_overview', include: :translations)
    unless api_overview.blank?
      translation = api_overview.translations.select{|t| t.language_id == current_language.id}.compact
      translation = api_overview.translations.select{|t| t.language_id == Language.english.id}.compact if translation.blank?
      @navigation_menu = translation.first.left_content rescue nil
      @navigation_menu.gsub!(/ class=['"]active['"]/, ' ')
      if params[:action] == "index"
        @navigation_menu.gsub!(/<li>\s+(<a href=\"\/api\">)/, "<li class='active'>\\1")
      else
        @navigation_menu.gsub!(/<li>\s+(<a href=\"\/api\/docs\/#{params[:action]}\">)/, "<li class='active'>\\1")
      end
    end
  end
end
