class Administrator::ContentPageController < AdminController

  layout 'left_menu'

  before_filter :set_layout_variables

  access_control :DEFAULT => 'Administrator - Site CMS'
  
 def index
   @page_title = 'Edit Page Contents'
   @content_sections = ContentSection.find(:all, :order => 'name')
   @content_section_id = params[:content_section_id] || @content_sections[0].id
   @content_section = ContentSection.find(@content_section_id)
   # get the content pages for the selected section or the first section
   @content_pages = ContentPage.find_all_by_content_section_id(@content_section_id, :order => 'sort_order, language_abbr')
   # show the selected page or the first page in the selection section
   content_page_id = params[:content_page_id] || @content_pages[0].id
   # get the page content for the selected (or first) page
   @page = ContentPage.find(content_page_id)
 end
  
 def update
   current_page = ContentPage.find(params[:id])
   new_page = ContentPage.update(params[:id], params[:page])
   new_page.update_attribute(:last_update_user_id, current_user.id)
   if new_page.valid?
     ContentPageArchive.backup(current_page) # backup old page
     expire_menu_caches(new_page)
     flash[:notice] = 'Content has been updated.'
   else
     flash[:error] = 'Some required fields were not entered (you must enter a title, and content OR a URL).'
   end
   redirect_to :action => 'index', :content_section_id => new_page.content_section.id, :content_page_id => new_page.id
 end
 
 # pull the updated content from the querystring to build the preview version of the page 
 def preview
   @content = ContentPage.new(params[:page])
   render :layout => 'admin_without_nav'
 end
 
 def create
   @content_section_id = params[:id]
   new_page = create_new_page(@content_section_id) 
   expire_menu_caches
   redirect_to :action => 'index', :content_section_id => new_page.content_section.id, :content_page_id => new_page.id, :new_page => 'true'
 end

 def destroy
   (redirect_to :action => 'index';return) unless request.method == :delete
   current_page = ContentPage.find(params[:id])
   current_page.last_update_user_id = current_user.id   
   ContentPageArchive.backup(current_page) # backup page   
   content_section_id = current_page.content_section_id
   current_page.destroy
   redirect_to :action => 'index', :content_section_id => content_section_id
 end
 
 # AJAX CALLs
 def get_content_pages
    # get the content pages for the content section ID passed in the querystring parameter
    @content_section_id = params[:id]
    @content_section = ContentSection.find(@content_section_id)
    @content_pages = ContentPage.find_all_by_content_section_id(@content_section_id, :order => 'sort_order, language_abbr')
    # get the first page in that section if we have pages
    if @content_pages.size>0 
      @page = ContentPage.find(@content_pages[0]) 
    else # otherwise redirect to create a new page (the first) in this section
      @page = create_new_page(@content_section_id) 
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
 
private 

  # expire the header and footer caches
  def expire_menu_caches(page = nil)
    list = ['top_nav', 'footer', 'exemplars'] # TODO - i18n
    list << page.page_name unless page.nil?
    expire_pages(list)
  end

  def create_new_page(content_section_id)
    new_page = ContentPage.new
    new_page.page_name = 'New Page'
    new_page.title = 'New Page'
    new_page.active = false
    new_page.url = ''
    new_page.main_content = 'Content goes here'
    new_page.left_content = ''
    new_page.content_section_id = content_section_id
    new_page.sort_order = 99
    new_page.save
    return new_page
  end
  
  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
