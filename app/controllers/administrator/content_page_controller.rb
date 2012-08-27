class Administrator::ContentPageController < AdminController

  layout 'left_menu'

  before_filter :set_layout_variables

  before_filter :restrict_to_admins

  def index
    @page_title = I18n.t("site_cms")
    @content_pages = ContentPage.find_top_level
  end

 def move_up
   current_page = ContentPage.find_by_id(params[:id])
   sort_order = current_page.sort_order
   new_sort_order = sort_order - 1
   #find page with the same parent with sort order = current sort order -1
   if swap_page = ContentPage.find_by_parent_content_page_id_and_sort_order(current_page.parent_content_page_id, new_sort_order)
     swap_page.update_column(:sort_order, sort_order)
   end
   current_page.update_column(:sort_order, new_sort_order)
   flash[:notice] = I18n.t("content_has_been_updated")
   redirect_to :action => 'index', :status => :moved_permanently
 end

 def move_down
   current_page = ContentPage.find(params[:id])
   sort_order = current_page.sort_order
   new_sort_order = sort_order + 1
   #find page with the same parent with sort order = current sort order +1
   #swap the two orders
   if swap_page = ContentPage.find_by_parent_content_page_id_and_sort_order(current_page.parent_content_page_id, new_sort_order)
     swap_page.update_column(:sort_order, sort_order)
   end
   current_page.update_column(:sort_order, new_sort_order)
   flash[:notice] = I18n.t("content_has_been_updated")
   redirect_to :action => 'index', :status => :moved_permanently
 end

 def update
   current_page = ContentPage.find(params[:id])
   new_page = ContentPage.update(params[:id], params[:page])
   new_page.update_attributes(:last_update_user_id => current_user.id)
   if new_page.valid?
     ContentPageArchive.backup(current_page) # backup old page
     expire_menu_caches(new_page)
     flash[:notice] = I18n.t("content_has_been_updated")
   else
     flash[:error] = I18n.t("some_required_fields_were_not_entered")
   end
   redirect_to :action => 'index', :content_page_id => new_page.id, :status => :moved_permanently
 end

 # pull the updated content from the querystring to build the preview version of the page
 def preview
   @page_title = params[:page][:translated_title]
   render :layout => 'v2/basic'
 end

 def new
   @navigation_tree = ContentPage.get_navigation_tree(params[:parent_content_page_id])
   @page_title = I18n.t("add_page")
   @page = ContentPage.new
   @page.set_translation_language(Language.english)
   @page.parent_content_page_id = params[:parent_content_page_id]
   @page.page_name = 'New Page'
   @page.translated_title = "New Page"
   @page.translated_main_content = "Main content for <b>New Page</b>"
   @page.translated_active_translation = true
   @page.current_translation_language = Language.english
   @language_id = @page.current_translation_language.id
 end

 def update_page
   @page_title = I18n.t("update_page")
   @page = ContentPage.find(params[:id])
   @navigation_tree = ContentPage.get_navigation_tree(@page.parent_content_page_id)
 end

 def save_updated_page
   current_page = ContentPage.find(params[:id])
   new_page = ContentPage.update(params[:id], params[:page])
   new_page.update_attributes(:last_update_user_id => current_user.id)
   if new_page.valid?
     ContentPageArchive.backup(current_page) # backup old page
     expire_menu_caches(new_page)
     flash[:notice] = I18n.t("content_has_been_updated")
   else
     flash[:error] = I18n.t("some_required_fields_were_not_entered")
   end
   redirect_to :action => 'index', :status => :moved_permanently
 end

 def destroy
   (redirect_to :action => 'index', :status => :moved_permanently;return) unless request.method == :delete
   current_page = ContentPage.find(params[:id])
   current_page.last_update_user_id = current_user.id
   ContentPageArchive.backup(current_page) # backup page
   parent_content_page_id = current_page.parent_content_page_id
   sort_order = current_page.sort_order
   current_page.destroy
   ContentPage.update_sort_order_based_on_deleting_page(parent_content_page_id, sort_order)
   redirect_to :action => 'index', :status => :moved_permanently
 end

 def update_language
   @page_title = I18n.t("update_language")
   @page = ContentPage.find(params[:id])
   @language = Language.find(params[:language_id])
   @page.set_translation_language(@language)
   @navigation_tree = ContentPage.get_navigation_tree(params[:id])

 end

 def add_language
   @page_title = I18n.t("add_language")
   @page = ContentPage.find(params[:id])
   @navigation_tree = ContentPage.get_navigation_tree(params[:id])

 end

 def save_translation
   page = ContentPage.find(params[:id])

   language = Language.find(params[:language_id]) rescue Language.find(params[:page][:current_translation_language])

   if language.id == nil
     language = Language.find(params[:page][:current_translation_language])
   end

   translated_page = TranslatedContentPage.find_by_content_page_id_and_language_id(page.id, language.id)

   TranslatedContentPageArchive.backup(translated_page) if translated_page

   translated_page = TranslatedContentPage.new if !translated_page

   translated_page.content_page = page
   translated_page.language_id = language.id
   translated_page.active_translation = params[:page][:translated_active_translation]
   translated_page.title = params[:page][:translated_title]
   translated_page.meta_keywords = params[:page][:translated_meta_keywords]
   translated_page.meta_description = params[:page][:translated_meta_description]
   translated_page.left_content = params[:page][:translated_left_content]
   translated_page.main_content = params[:page][:translated_main_content]
   translated_page.save

   flash[:notice] = I18n.t("translation_saved")
   redirect_to :action => 'index', :status => :moved_permanently

 end

 def delete_translation
   translation_content_page = TranslatedContentPage.find_by_content_page_id_and_language_id(params[:id], params[:language_id])
   TranslatedContentPage.delete(translation_content_page.id) if translation_content_page
   flash[:notice] = I18n.t("translation_deleted")
   redirect_to :action => 'index', :status => :moved_permanently
 end

  # AJAX CALLs
  def get_content_pages
    @content_pages = ContentPage.find_all(:order => 'sort_order, language_abbr')
    # get the first page if we have pages
    if @content_pages.size>0
      @page = ContentPage.find(@content_pages[0])
    else # otherwise redirect to create a new page (the first)
      @page = create_new_page
    end
    render :update do |page|
      page.replace_html 'content_page_list', :partial => 'content_page_list'
      page.replace_html 'content_page', :partial => 'form'
    end
  end

  def get_page_content
    # get the specific page for the page ID passed in by the ID querystring parameter
    @page = ContentPage.find(params[:id], :include => :content_page_archives)
    render :update do |page|
      page.replace_html 'content_page', :partial => 'form'
    end
  end

  def get_archive_page_content
    # get the specific archived page for the page ID  & archieve ID using the querystring parameters
    @page = ContentPage.find(params[:page_id], :include => :content_page_archives)
    @archived_page = ContentPageArchive.find_by_id_and_content_page_id(params[:archieve_id],params[:page_id])
    @page.title = @archived_page.title
    @page.page_name = @archived_page.page_name
    @page.left_content = @archived_page.left_content
    @page.main_content = @archived_page.main_content
    @page.created_at = @archived_page.created_at
    render :update do |page|
      page.replace_html 'content_page', :partial => 'form'
    end
  end

  def get_new_page_sort_order(parent_content_page_id)
    content_pages = ContentPage.find_all_by_parent_content_page_id(parent_content_page_id)
    max_order = 0

    for content_page in content_pages
      max_order = content_page.sort_order if max_order < content_page.sort_order
    end

    max_order = max_order + 1
    return max_order
  end

  def save_new_page
    page = ContentPage.new
    page.page_name = params[:page][:page_name]
    page.sort_order = get_new_page_sort_order(params[:page][:parent_content_page_id])
    page.active = params[:page][:active]
    page.parent_content_page_id = params[:page][:parent_content_page_id]
    page.last_update_user_id = current_user.id
    page.sort_order = ContentPage.max_view_order_by_parent_id(params[:page][:parent_content_page_id]) + 1
    if page.valid?
      page.save
      translated_page = TranslatedContentPage.new
      translated_page.content_page = page
      translated_page.language_id = params[:page][:current_translation_language]
      translated_page.active_translation = params[:page][:translated_active_translation]
      translated_page.title = params[:page][:translated_title]
      translated_page.meta_keywords = params[:page][:translated_meta_keywords]
      translated_page.meta_description = params[:page][:translated_meta_description]
      translated_page.left_content = params[:page][:translated_left_content]
      translated_page.main_content = params[:page][:translated_main_content]
      translated_page.save

      expire_menu_caches(page)
      flash[:notice] = I18n.t("content_has_been_updated")
      redirect_to :action => 'index', :status => :moved_permanently
    else
      flash[:error] = I18n.t("some_required_fields_were_not_entered")
    end

  end

private

  # expire the header and footer caches
  def expire_menu_caches(page = nil)
    list = ['top_nav', 'footer'] # TODO - i18n
    list << page.page_name unless page.nil?
    expire_pages(list)
  end


  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
