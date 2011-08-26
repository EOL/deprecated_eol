class Api::DocsController < ApiController
  layout 'v2/basic'

  before_filter :set_navigation_menu
  def index
    @page_title = I18n.t(:eol_api)
  end
  def ping
    @page_title = I18n.t(:eol_api__ping)
  end
  def search
    @page_title = I18n.t(:eol_api__search)
  end
  def data_objects
    @page_title = I18n.t(:eol_api__data_objects)
  end
  def pages
    @page_title = I18n.t(:eol_api__pages)
  end
  def hierarchy_entries
    @page_title = I18n.t(:eol_api__hierarchy_entries)
  end
  def provider_hierarchies
    @page_title = I18n.t(:eol_api__provider_hierarchies)
  end
  def hierarchies
    @page_title = I18n.t(:eol_api__hierarchies)
  end
  def search_by_provider
    @page_title = I18n.t(:eol_api__search_by_provider)
  end
  def collections
    @page_title = I18n.t(:eol_api__collections)
  end

private
  def set_navigation_menu
    api_overview = ContentPage.find_by_page_name('api_overview', :include => :translations)
    translation = api_overview.translations.select{|t| t.language_id == current_user.language_id}.compact
    translation ||= api_overview.translations.select{|t| t.language_id == Language.english.id}.compact
    @navigation_menu =  translation.first.left_content rescue nil
  end
end
