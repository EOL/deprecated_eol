class Administrator::SearchSuggestionController < AdminController

  layout 'deprecated/left_menu'

  before_filter :set_layout_variables

  helper :resources

  before_filter :restrict_to_admins

  def index
    puts "*" * 1000
    load_suggestions
  end

  def new
    @page_title = I18n.t("new_search_suggestion")
    @search_suggestion = SearchSuggestion.new
    store_location(referred_url) if request.get?
  end

  def edit
    @page_title = I18n.t("edit_search_suggestion")
    @search_suggestion = SearchSuggestion.find(params[:id])
    store_location(referred_url) if request.get?
  end

  def create
    @search_suggestion = SearchSuggestion.new(params[:search_suggestion])
    if @search_suggestion.save
      flash[:notice] = I18n.t(:search_suggestion_created)
      redirect_back_or_default(url_for(action: 'index'))
    else
      render action: "new"
    end
  end

  def update
    @search_suggestion = SearchSuggestion.find(params[:id])
    if @search_suggestion.update_attributes(params[:search_suggestion])
      flash[:notice] = I18n.t(:search_suggestion_updated)
      redirect_back_or_default(url_for(action: 'index'))
    else
      render action: "edit"
    end
  end

  def destroy
    SearchSuggestion.delete_all(id: params[:id])
    load_suggestions
    redirect_to action: "index", status: :moved_permanently
  end

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

  def load_suggestions
    @page_title = I18n.t("search_suggestions")
    @term_search_string = params[:term_search_string] || ''
    search_string_parameter = '%' + @term_search_string + '%'
    # let us go back to a page where we were
    page = params[:page] || "1"
    @search_suggestions = SearchSuggestion.paginate(
      conditions: ['term like ?', search_string_parameter],
      order: 'term asc', page: page)
    SearchSuggestion.preload_associations(@search_suggestions, { taxon_concept: { preferred_entry: { hierarchy_entry: { name: :ranked_canonical_form } } } })
    @search_suggestions_count = SearchSuggestion.count(conditions: ['term like ?', search_string_parameter])
  end

end
