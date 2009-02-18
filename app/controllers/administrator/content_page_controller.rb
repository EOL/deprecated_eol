class Administrator::ContentPageController < AdminController

  access_control :DEFAULT => 'Administrator - Site CMS'
  
   def index
   
   # get the content sections
   @content_sections=ContentSection.find(:all, :order=>'name')
   
   @content_section_id=params[:content_section_id] || @content_sections[0].id
   
   # this is here so that the drop-down menu of sections default value will be correctly selected
   @content_section=ContentSection.find(@content_section_id)
   
   # get the content pages for the selected section or the first section
   @content_pages=ContentPage.find_all_by_content_section_id(@content_section_id, :order=>'sort_order,language_abbr')

   # show the selected page or the first page in the selection section
   content_page_id=params[:content_page_id] || @content_pages[0].id
   
   # get the page content for the selected (or first) page
   @page=ContentPage.find(content_page_id)

 end
  
 def update
      
   # get current page (not updated yet...)    
   current_page=ContentPage.find(params[:id])

   # update the page
   new_page=ContentPage.update(params[:id],params[:page])
   new_page.update_attribute(:last_update_user_id,current_user.id)

   if new_page.valid?
     ContentPageArchive.backup(current_page) # backup old page
     expire_cache(new_page.page_name) 
     expire_menu_caches
     flash[:notice]='Content has been updated.'
   else
     flash[:error]='Some required fields were not entered (you must enter a title, and content OR a URL).'
   end
   redirect_to :action=>'index', :content_section_id=>new_page.content_section.id, :content_page_id=>new_page.id
   
 end
 
 def preview
   
  # pull the updated content from the querystring to build the preview version of the page 
  @content=ContentPage.new(params[:page])
   
 end
 
 def create

   @content_section_id=params[:id]
   new_page=create_new_page(@content_section_id) 
   expire_menu_caches
   redirect_to :action=>'index', :content_section_id=>new_page.content_section.id, :content_page_id=>new_page.id, :new_page=>'true'
   
 end

 def destroy
   
   (redirect_to :action=>'index';return) unless request.method == :delete
   
   current_page = ContentPage.find(params[:id])
   current_page.last_update_user_id=current_user.id   
   ContentPageArchive.backup(current_page) # backup page   
   content_section_id=current_page.content_section_id
   current_page.destroy

   redirect_to :action=>'index', :content_section_id=>content_section_id
 
 end
 
   
 # AJAX CALLs
 def get_content_pages
   
    # get the content pages for the content section ID passed in the querystring parameter
    @content_section_id=params[:id]

    @content_section=ContentSection.find(@content_section_id)
    @content_pages=ContentPage.find_all_by_content_section_id(@content_section_id, :order=>'sort_order,language_abbr')

    # get the first page in that section if we have pages
    if @content_pages.size>0 
      @page=ContentPage.find(@content_pages[0]) 
    else # otherwise redirect to create a new page (the first) in this section
      @page=create_new_page(@content_section_id) 
    end
    
    render :update do |page|
        page.replace_html 'content_page_list', :partial => 'content_page_list'
        page.replace_html 'content_page', :partial => 'form'
    end   
    
 end
 
  def get_page_content
     
    # get the specific page for the page ID passed in by the ID querystring parameter
    @page=ContentPage.find(params[:id],:include=>:content_page_archives)
    
    render :update do |page|
        page.replace_html 'content_page', :partial => 'form'
    end  
    
 end
 
 
 def get_archived_page
   
     # get the original page
     @page=ContentPage.find(params[:content_page_id])
   
     # get the selected achived page
     @content_page_archive=ContentPageArchive.find(params[:content_page_archive_id])
     
     # update the original page with the archived values
     @page.left_content=@content_page_archive.left_content
     @page.main_content=@content_page_archive.main_content
     @page.sort_order=@content_page_archive.sort_order
     @page.page_name=@content_page_archive.page_name
     @page.language_key=@content_page_archive.language_key
     @page.url=@content_page_archive.url
     @page.content_section_id=@content_page_archive.content_section_id
     @page.title=@content_page_archive.title
     @page.open_in_new_window=@content_page_archive.open_in_new_window
     
     render :update do |page|
        page.replace_html 'content_page', :partial => 'form'
     end  
    
 end
 
 private 
 def create_new_page(content_section_id)
   new_page=ContentPage.new
   new_page.page_name='New Page'
   new_page.title='New Page'
   new_page.active=true
   new_page.url=''
   new_page.main_content='Content goes here'
   new_page.left_content=''
   new_page.content_section_id=content_section_id
   new_page.sort_order=99
   new_page.save
   return new_page
 end
 
end
