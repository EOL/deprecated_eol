class WikipediaImportsController < ApplicationController

  layout 'basic'

  before_filter :check_authentication

  # GET /wikipedia_imports/new
  def new
    @page_title = I18n.t(:wikipedia_queue_new_page_title)
    store_location(params[:return_to]) unless params[:return_to].blank?
    @new_wikipedia_queue = WikipediaQueue.new
    access_denied unless current_user.can_create?(@new_wikipedia_queue)
    curators_page = ContentPage.find_by_page_name('curators', include: :translations)
    unless curators_page.blank?
      translation = curators_page.translations.select{|t| t.language_id == current_language.id}.compact
      translation ||= curators_page.translations.select{|t| t.language_id == Language.english.id}.compact
      @navigation_menu =  translation.first.left_content rescue nil
    end
  end

  # POST /wikipedia_imports
  def create
    access_denied unless current_user.is_curator? || current_user.is_admin?
    @revision_url = params[:wikipedia_queue][:revision_url]
    if matches = @revision_url.match(/^http:\/\/en\.wikipedia\.org\/w\/index\.php\?title=(.*?)&oldid=([0-9]{9})$/i)
      flash[:notice] = I18n.t(:wikipedia_queue_create_successful_notice, article: matches[1], rev: matches[2])
      WikipediaQueue.create(revision_id: matches[2], user_id: current_user.id)
      redirect_back_or_default(new_wikipedia_queue_path)
    else
      flash.now[:error] = I18n.t(:wikipedia_queue_create_unsuccessful_error)
      @new_wikipedia_queue = WikipediaQueue.new(params[:wikipedia_queue])
      render :new
    end
  end

end
