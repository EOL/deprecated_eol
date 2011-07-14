class Administrator::NewsItemController < AdminController

  layout 'left_menu'

  before_filter :set_layout_variables

  helper :resources

  access_control :news_items
  
  def index
    @page_title = I18n.t("news_items")
    @term_search_string=params[:term_search_string] || ''
    search_string_parameter='%' + @term_search_string + '%' 
    @news_items=NewsItem.paginate(:conditions=>['exists (select * from translated_news_items where body like ?)',search_string_parameter],:order=>'display_date desc',:page => params[:page])
    @news_items_count=NewsItem.count(:conditions=>['exists (select * from translated_news_items where body like ?)',search_string_parameter])
  end

  def new
    @page_title = I18n.t("new_news_item")
    store_location(referred_url) if request.get?    
    @news_item = NewsItem.new
    @news_item.set_translation_language(Language.english)
    @news_item.translated_active_translation = true
    @news_item.current_translation_language = Language.english
    @language_id = @news_item.current_translation_language.id
    @news_item.translated_title = "News title"
    @news_item.translated_body = "News details"
  end

  def edit
    @page_title = I18n.t("edit_news_item")
    store_location(referred_url) if request.get?            
    @news_item = NewsItem.find(params[:id])
  end

  def create
    @news_item = NewsItem.new(params[:news_item])
    if @news_item.save
      translated_news_item = TranslatedNewsItem.new
      translated_news_item.news_item_id = @news_item.id
      translated_news_item.title = params[:news_item][:translated_title]
      translated_news_item.body = params[:news_item][:translated_body]
      translated_news_item.language_id = params[:news_item][:current_translation_language]
      translated_news_item.active_translation = params[:news_item][:translated_active_translation]
      translated_news_item.save
      flash[:notice] = I18n.t("the_news_item_was_successfully")
      expire_cache('Home')
      redirect_back_or_default(url_for(:action=>'index'))
    else
      render :action => 'new' 
    end
  end

  def update
    @news_item = NewsItem.find(params[:id])
    if @news_item.update_attributes(params[:news_item])
      flash[:notice] = I18n.t("the_news_item_was_successfully_")
      expire_cache('Home')
      redirect_back_or_default(url_for(:action=>'index'))
    else
      render :action => 'edit' 
    end
  end
  
  def delete_translation
    translation_news_item = TranslatedNewsItem.find_by_news_item_id_and_language_id(params[:id], params[:language_id])
    translation_news_item.destroy
    flash[:notice] = I18n.t("translation_deleted")
    redirect_to :action => 'index'
  end

  def destroy
    (redirect_to referred_url;return) unless request.method == :delete
    for translated_news_item in TranslatedNewsItem.find_all_by_news_item_id(params[:id])
      translated_news_item.destroy
    end
    @news_item = NewsItem.find(params[:id])    
    @news_item.destroy
    expire_cache('Home')
    redirect_to referred_url
  end
  
  def add_language
    @page_title = I18n.t("add_language")
    @news_item = NewsItem.find(params[:id])       
  end
  
  def update_language
    @page_title = I18n.t("update_language")
    @news_item = NewsItem.find(params[:id])
    @language = Language.find(params[:language_id])
    @news_item.set_translation_language(@language)  
    
  end
  
  def save_translation
   news_item = NewsItem.find(params[:id])   
   language = Language.find(params[:language_id]) rescue Language.find(params[:news_item][:current_translation_language])  
   
   if language.id == nil
     language = Language.find(params[:news_item][:current_translation_language])
   end
   
   translated_news_item = TranslatedNewsItem.find_by_news_item_id_and_language_id(news_item.id, language.id)
   
   translated_news_item = TranslatedNewsItem.new if translated_news_item.nil?
   
   translated_news_item.news_item = news_item
   translated_news_item.language_id = language.id
   translated_news_item.active_translation = params[:news_item][:translated_active_translation]
   translated_news_item.title = params[:news_item][:translated_title]
   translated_news_item.body = params[:news_item][:translated_body]
   
   translated_news_item.save
   
   flash[:notice] = I18n.t("translation_saved")
   redirect_to :action => 'index' 
   
 end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
