class Api::DocsController < ApiController
  layout 'v2/basic'

  before_filter :set_navigation_menu
  def index
    @page_title = I18n.t(:eol_api)
  end
  def ping
    @page_title = I18n.t(:eol_api_ping)
  end
  def search
    @page_title = I18n.t(:eol_api_search)
  end
  def data_objects
    @page_title = I18n.t(:eol_api_data_objects)
  end
  def pages
    @page_title = I18n.t(:eol_api_pages)
  end
  def hierarchy_entries
    @page_title = I18n.t(:eol_api_hierarchy_entries)
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
  def set_navigation_menu
    api_overview = ContentPage.find_by_page_name('api_overview', :include => :translations)
    unless api_overview.blank?
      translation = api_overview.translations.select{|t| t.language_id == current_language.id}.compact
      translation ||= api_overview.translations.select{|t| t.language_id == Language.english.id}.compact
      @navigation_menu =  translation.first.left_content rescue nil
    end
  end
end
