class TaxaController < ApplicationController
  
  layout 'main'
  before_filter :set_user_settings, :only=>[:show,:search,:settings]
  before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN   # if we happen to be on an SSL page, go back to http
  
  if $SHOW_SURVEYS
    before_filter :check_for_survey, :only=>[:show,:search,:settings]
    after_filter :count_page_views, :only=>[:show,:search,:settings]
  end

  def index
    #this is cheating because of mixing taxon and taxon concept use of the controller
    
    # you need to be a content partner and logged in to get here
    if current_agent.nil?
      redirect_to(home_page_url)
      return
    end
    
    if params[:harvest_event_id] && params[:harvest_event_id].to_i > 0
      page = params[:page] || 1
      @harvest_event = HarvestEvent.find(params[:harvest_event_id])
      @taxa = Taxon.paginate_by_sql("
        select t.*, he.taxon_concept_id
        from harvest_events h 
          join harvest_events_taxa ht 
            on h.id = ht.harvest_event_id 
          join taxa t 
            on t.id = ht.taxon_id 
          join hierarchy_entries he 
            on he.id = t.hierarchy_entry_id 
        where h.id=#{params[:harvest_event_id].to_i} 
        order by t.scientific_name" , :page => page)
      render :html => 'content_partner'
    else
      redirect_to(:action=>:show, :id=>params[:id])
    end
  end
  
  def boom
    # a quick way to test exception notifications, just raise the error!
    raise "boom" 
  end
  
  def search_clicked
    
    # update the search log if we are coming from the search page, to indicate the user got here from a search
    update_logged_search :id=>params[:search_id],:taxon_concept_id=>params[:id] if params.key? :search_id 
    redirect_to taxon_url, :id=>params[:id]
  
  end

  # a permanent redirect to the new taxon page
  def taxa
  #  pp params
    headers["Status"] = "301 Moved Permanently"
    redirect_to(params.merge(:controller => 'taxa', :action => 'show', :id => HierarchyEntry.find(params[:id]).taxon_concept_id))
  end
  
  # Main taxon viewmysql
  def show
    # set default taxa id if one is not supplied in querystring
    @taxon_id = params[:id]

    @specify_category_id=params[:category_id] || 'default'

    raise "taxa id not supplied" if @taxon_id.nil? 
    
    # reset the content level if it is in the querystring NOTE the expertise level is set by pre filter set_user_settings()
    current_user.content_level = params[:content_level] if ['1','2','3','4'].include?(params[:content_level])
    
    begin
      @taxon = TaxonConcept.find(@taxon_id)
      @taxon.current_user = current_user
    rescue ActiveRecord::RecordNotFound
      raise "taxa does not exist"  
    end
        
    # run all the queries if the page cannot be cached or the fragment is not found
    if !allow_page_to_be_cached? || @specify_category_id != 'default' || !read_fragment(:controller=>'taxa',:part=>'page_' + @taxon_id.to_s + '_' + current_user.language_abbr + '_' + current_user.expertise.to_s + '_' + current_user.vetted.to_s + '_' + current_user.default_taxonomic_browser.to_s + '_' + current_user.can_curate?(@taxon).to_s)    
      
      @cached=false
      
      @taxon.current_user = current_user

      # get available media types
      @available_media = @taxon.available_media
        
      # TODO - all these @taxon.map/videos/images don't need to be full-class @variables.... just use taxon!
      # get distribution map information
      @map = @taxon.map if @available_media[:map]
    
      # get videos for this taxon
      @videos=@taxon.videos if @available_media[:video]
              
      # get first set of images and if more images are available (for paging)
      # TODO - this (image_page) is broken.  Can we remove it?
      @image_page = (params[:image_page] || 1).to_i
      @taxon.current_agent = current_agent unless current_agent.nil?
      @images     = @taxon.images
      @show_next_image_page_button = @taxon.more_images # indicates if more images are available
      @default_image = @images[0].smart_image unless @images.nil? or @images.blank?
           
      # find first valid content area to use
      first_content_item = @taxon.table_of_contents(:vetted_only=>current_user.vetted).detect {|item| item.has_content? }
      @category_id = first_content_item.nil? ? nil : first_content_item.id 
      @category_id = @specify_category_id unless @specify_category_id=='default'
      
      # default to regular page separator if we can't find a specific kingdom
      @page_separator="page-separator-general"
      @page_separator="page-separator-#{@taxon.kingdom.id}" unless @taxon.kingdom.nil? || !$KINGDOM_IDs.include?(@taxon.kingdom.id.to_s) 
       
      @content     = @taxon.content_by_category(@category_id) unless @category_id.nil? || @taxon.table_of_contents(:vetted_only=>current_user.vetted).blank?
      @random_taxa = RandomTaxon.random_set(5)

      @ping_host_urls = @taxon.ping_host_urls
     
      # just grab the first rank name (will be "taxon" if no rank available)
      @rank=@taxon.hierarchy_entries[0].rank_label.capitalize
      
      # log data objects shown and build an array of data_object_ids to log, so we can stick this info in the cached page and when the page comes from the cache, we can log on the server side
      @data_object_ids_to_log=Array.new
      unless @images.blank?
        log_data_objects_for_taxon_concept @taxon, @images.first 
        @data_object_ids_to_log << @images.first.id
      end
      unless @content.nil? || @content[:data_objects].blank?
        log_data_objects_for_taxon_concept @taxon, *@content[:data_objects]
        @content[:data_objects].each {|data_object| @data_object_ids_to_log << data_object.id }
      end
      @data_object_ids_to_log.compact!
      
      @contains_unvetted_objects = false # per request by Jim Edwards on 11/5/2008 in Mexico, we should *not* show the top banner indicating there are unvetted objects on a page
      #@contains_unvetted_objects=((!current_user.vetted && @taxon.includes_unvetted) ? true : false)  # uncomment this line to show unvetted warning on page with those objects
    
    else
      
      @cached=true
        
    end # end get full page since we couldn't read from cache
   
    @taxon_page_title=remove_html(@taxon.title) # we always need the title
        
    render :template=>'/taxa/show_cached' if allow_page_to_be_cached? && @specify_category_id == 'default' # if caching is allowed, see if fragment exists using this template
    
  end
  
  # execute search and show results
  def search
    
    current_user.content_level = params[:content_level] unless params[:content_level].nil?
    params[:search_language] ||= '*'
    params[:search_type] = EOLConvert.get_search_type(params[:search_type])
    params[:content_level] ||= '1'
    params[:q] ||= ''
    
    last_published=HarvestEvent.last_published if params[:search_type].downcase == 'text' && allow_page_to_be_cached?
    @last_harvest_event_id=(last_published.blank? ? "0" : last_published.id.to_s)
    
    if params[:search_type] == 'text' && (!allow_page_to_be_cached? || !read_fragment(:controller=>'taxa',:part=>'search_' + params[:search_language] + '_' + params[:q] + '_' + current_user.vetted.to_s + '_' + @last_harvest_event_id))           
      
      @search = Search.new(params, request, current_user, current_agent)  # this is a non-cached text search      
      @cached = false
        
      # TODO - There is a much better way to do this, please clean me - it is also duplicated in search.rb model  
      # if we have only one result, go straight to that page
      if @search.search_returned && @search.total_search_results == 1
        #taxon_id = (@search.common_name_results[0][0] || @search.scientific_name_results[0][0] || @search.tag_results[0][0].id)
        taxon_id = @search.common_results.empty? ? nil : @search.common_results[0][:id]
        taxon_id = taxon_id ? taxon_id : (@search.scientific_results.empty? ? nil : @search.scientific_results[0][:id])
        taxon_id = taxon_id ? taxon_id : (@search.tag_results.empty? ? nil: @search.tag_results[0][0].id)
        taxon_id = taxon_id ? taxon_id : @search.suggested_searches[0].taxon_id
        redirect_to :controller => 'taxa', :action => 'show', :id => taxon_id
      end
      
    elsif params[:search_type] == 'text' # this is a cached text search
      
      @search = Search.new(params,request,current_user,current_agent,false) # set up some variables needed on the page, but don't actually execute the search
      @cached = true
      
    else # this is a tag search (which is never cached)
      
      @search = Search.new(params,request,current_user,current_agent)
      @cached = false
      
    end
    
  end
  
  # page that will allows a non-logged in user to change content settings
  def settings

    store_location(params[:return_to]) if !params[:return_to].nil? && request.get? # store the page we came from so we can return there if it's passed in the URL

    # if the user is logged in, they should be at the profile page
    if logged_in?
      redirect_to(profile_url)
      return
    end
    
    # grab logged in user
    @user = current_user
            
    unless request.post? # first time on page, get current settings
      # set expertise to a string so it will be picked up in web page controls
      @user.expertise=current_user.expertise.to_s
      return
    end
             
    @user.attributes=params[:user]
    set_current_user(@user)
    flash[:notice] = "Your preferences have been updated."[:your_preferences_have_been_updated]
    redirect_back_or_default
       
  end
  
  ################
  # AJAX CALLS
  ################

  # AJAX: Render the requested citation into a floating div
  # TODO: Remove if it continues to not be used
  def citation
    
    @taxon_id = params[:id]  
    render :partial=>'citation',:layout=>false
    
  end

  # AJAX: Render the requested citation into an endnote file
  # TODO: Remove if it continues to not be used
  def endnote
    
    taxon_id = params[:id]  
    taxon    = TaxonConcept.find(taxon_id)

    taxon.current_user = current_user
    
    unless taxon.nil?
        endnote_citation=''
        ## TODO: This is obviously hardcoded and would need to be updated with dynamic citation data when we do this
        endnote_citation+="%0 Web Page\n"
        endnote_citation+="%T Taxonomic and natural history description of FAM: ARANEIDAE, Araneus marmoreus Clerck, 1757\n"
        endnote_citation+="%A Shorthouse, David P.\n"
        endnote_citation+="%E Shorthouse, David P.\n"
        endnote_citation+="%D 2006\n"
        endnote_citation+="%W http://www.canadianarachnology.org/data/canada_spiders/\n"
        endnote_citation+="%N " + Time.now.strftime("%m/%d/%Y %H:%M:%S") +"\n"
        endnote_citation+="%U http://www.canadianarachnology.org/data/spiders/15005\n"
        endnote_citation+="%~ The Nearctic Spider Database\n"
        endnote_citation+="%> http://www.canadianarachnology.org/data/spiderspdf/15005/Araneus%20marmoreus\n"
        
        send_data(endnote_citation,:filename=>taxon.title[0..20] + '.enw',:type=>'application/x-endnote-refer',:disposition=>'attachment')
    end
    
  end
  
  # AJAX: Render the requested content page
  def content

    if !request.xhr?
      render :nothing=>true
      return
    end
        
    @taxon_id    = params[:id]
    @taxon       = TaxonConcept.find(@taxon_id) 
    @category_id = params[:category_id].to_i
    @taxon.current_agent = current_agent unless current_agent.nil?
    @taxon.current_user = current_user
    if @category_id == TocItem.search_the_web.id
      render :update do |page|
        page.replace_html 'center-page-content', :partial => 'content_search_the_web.html.erb'
        page << "$('current_content').value = '#{@category_id}';"
        page['center-page-content'].set_style :height => 'auto'
      end
    else
      @content     = @taxon.content_by_category(@category_id)
      @ajax_update=true
      if @content.nil?
        render :text => '[content missing]'
      else
        render :update do |page|
          page.replace_html 'center-page-content', :partial => 'content.html.erb'
          page << "$('current_content').value = '#{@category_id}';"
          page << "Event.addBehavior.reload();"
          page['center-page-content'].set_style :height => 'auto'
        end
      end
    end
    
    log_data_objects_for_taxon_concept @taxon, *@content[:data_objects] unless @content.nil?
    
  end
  
  # AJAX: Render the requested image collection by taxon_id and page
  def image_collection
   
    if !request.xhr?
      render :nothing=>true
      return
    end  
    
    @image_page = (params[:image_page] ||= 1).to_i
    @taxon_id   = params[:taxon_id]
    @taxon      = TaxonConcept.find(@taxon_id) 
    @taxon.current_user = current_user
    @taxon.current_agent = current_agent
    start       = $MAX_IMAGES_PER_PAGE * (@image_page - 1)
    last        = start + $MAX_IMAGES_PER_PAGE - 1
    @images     = @taxon.images[start..last]

    @show_next_image_page_button = (@taxon.images.length > (last + 1))
    
    if @images.nil?
      render :nothing=>true
    else
      render :update do |page|
        page.replace_html 'image-collection', :partial => 'image_collection' 
      end
    end
    
  end
  
  # AJAX: show the requested video
  def show_video

   if !request.xhr?
     render :nothing=>true
     return
   end
       
    @video_url=params[:video_url]
    video_type=params[:video_type].downcase
         
    render :update do |page|
      page.replace_html 'video-player', :partial => 'video_' + video_type
    end
    
  end
  
  # AJAX: used to show a pop-up in a floating div, all views are in the "popups" subfolder
  def show_popup
    
     if !params[:name].blank? && request.xhr?
       template=params[:name]
       @taxon_name=params[:taxon_name] || "this taxon"
       render :layout=>false, :template=>'popups/' + template
     else
       render :nothing=>true
     end
   
  end
 
  # AJAX: used to record the response that the user sends to the survey
  def survey_response
    
    user_response=params[:user_response]
    
    SurveyResponse.create(
      :taxon_id=>params[:taxon_id],
      :ip_address=>request.remote_ip,
      :user_agent=>request.user_agent,
      :user_id=>current_user.id,
      :user_response=>user_response
      )     
    
    render :nothing => true
    
  end

  # AJAX: used to log when an object is viewed
  def view_object
    if !params[:id].blank? && request.post?  
      taxon = params[:taxon_concept_id].to_i
      # log each data object ID specified (separate multiple with commas)
      params[:id].split(",").each { |id| log_data_objects_for_taxon_concept taxon, DataObject.find_by_id(id.to_i) }
    end
    render :nothing => true
  end
    
  ###############################################
  protected
  
    # Set the page expertise and vetted defaults, get from  querystring, update the session with this value if found
    def set_user_settings

      expertise = params[:expertise].to_sym if ['novice','middle','expert'].include?(params[:expertise])
      current_user.expertise=expertise unless expertise.nil?

      vetted = params[:vetted]
      current_user.vetted=EOLConvert.to_boolean(vetted) unless vetted.blank? 
      
      # save user in database if they are logged in
      current_user.save if logged_in?
      
    end
        
end
