class Administrator::SearchSuggestionController < AdminController

  layout 'left_menu'

  before_filter :set_layout_variables

  helper :resources

  access_control :DEFAULT => 'Administrator - Site CMS'

  def index
    @page_title = 'Search Suggestions'
    @term_search_string = params[:term_search_string] || ''
    search_string_parameter = '%' + @term_search_string + '%'
    # let us go back to a page where we were
    page = params[:page] || "1"
    @search_suggestions = SearchSuggestion.paginate(
      :conditions => ['term like ?', search_string_parameter],
      :order => 'term asc', :page => page)
    @search_suggestions_count = SearchSuggestion.count(:conditions => ['term like ?', search_string_parameter])
  end

  def new
    @page_title = 'New Search Suggestion'
    @search_suggestion = SearchSuggestion.new
    store_location(referred_url) if request.get?
  end

  def edit
    @page_title = 'Edit Search Suggestion'
    @search_suggestion = SearchSuggestion.find(params[:id])
    store_location(referred_url) if request.get?
  end

  def create
    @search_suggestion = SearchSuggestion.new(params[:search_suggestion])
    if @search_suggestion.save
      flash[:notice] = 'The search suggestion was successfully created.'
      redirect_back_or_default(url_for(:action => 'index'))
    else
      render :action => "new"
    end
  end

  def update
    @search_suggestion = SearchSuggestion.find(params[:id])
    if @search_suggestion.update_attributes(params[:search_suggestion])
      flash[:notice] = 'The search suggestion was successfully updated.'
      redirect_back_or_default(url_for(:action => 'index'))
    else
      render :action => "edit"
    end
  end

  def destroy
    (redirect_to referred_url;return) unless request.method == :delete
    @search_suggestion = SearchSuggestion.find(params[:id])
    @search_suggestion.destroy
    redirect_to referred_url
  end

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
