class Administrator::NewsItemController < AdminController

  layout 'left_menu'

  before_filter :set_layout_variables

  helper :resources

  before_filter :restrict_to_admins

  def index
    @page_title = I18n.t("news_items")
    @term_search_string=params[:term_search_string] || ''
    search_string_parameter='%' + @term_search_string + '%'
    @search_language = params[:search_language] || Language.english.id
    @news_items=NewsItem.paginate(:conditions=>['language_id=? and (title like ? or abstract like ? or description like ?)',@search_language,search_string_parameter,search_string_parameter,search_string_parameter],:order=>'display_date desc',:page => params[:page])
    @news_items_count=NewsItem.count(:conditions=>['language_id=? and (title like ? or abstract like ? or description like ?)',@search_language,search_string_parameter,search_string_parameter,search_string_parameter])
  end

  def new
    @page_title = I18n.t("new_news_item")
    store_location(referred_url) if request.get?
    @news_item = NewsItem.new
    @news_item.display_date = DateTime.now
    @news_item.activated_on = DateTime.now
    @news_item.active = true
    @news_item.language = Language.english
    @language_id = @news_item.language.id
    @news_item.title = "News title"
    @news_item.abstract = "News abstract"
  end

  def edit
    @page_title = I18n.t("edit_news_item")
    store_location(referred_url) if request.get?
    @news_item = NewsItem.find(params[:id])
  end

  def create
    @news_item = NewsItem.new(params[:news_item])
    if @news_item.save
      flash[:notice] = I18n.t(:the_news_item_created)
      expire_cache('Home')
      redirect_back_or_default(url_for(:action=>'index'))
    else
      render :action => 'new'
    end
  end

  def update
    @news_item = NewsItem.find(params[:id])
    if @news_item.update_attributes(params[:news_item])
      flash[:notice] = I18n.t(:the_news_item_updated)
      expire_cache('Home')
      redirect_back_or_default(url_for(:action=>'index'))
    else
      render :action => 'edit'
    end
  end

  def destroy
    (redirect_to referred_url, :status => :moved_permanently;return) unless request.method == :delete
    @news_item = NewsItem.find(params[:id])
    @news_item.destroy
    expire_cache('Home')
    redirect_to referred_url, :status => :moved_permanently
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
