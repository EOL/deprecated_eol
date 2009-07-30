class TaxaController < ApplicationController

  layout 'main'
  prepend_before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN   # if we happen to be on an SSL page, go back to http
  before_filter :set_user_settings, :only=>[:show,:search,:settings]
  before_filter :set_session_hierarchy_variable, :only => [:show]

  if $SHOW_SURVEYS
    before_filter :check_for_survey, :only=>[:show,:search,:settings]
    after_filter :count_page_views, :only=>[:show,:search,:settings]
  end

  def index
    #this is cheating because of mixing taxon and taxon concept use of the controller

    # you need to be a content partner and logged in to get here
    if current_agent.nil?
      redirect_to(root_url)
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
    update_logged_search :id=>params[:search_id], :taxon_concept_id=>params[:id] if params.key? :search_id 
    redirect_to taxon_url, :id=>params[:id]

  end

  # a permanent redirect to the new taxon_concept page
  def taxa
    headers["Status"] = "301 Moved Permanently"
    redirect_to(params.merge(:controller => 'taxa', :action => 'show', :id => HierarchyEntry.find(params[:id]).taxon_concept_id))
  end

  # Main taxon_concept view
  def show    
    
    if this_request_is_really_a_search
      do_the_search
      return
    end
    
    @taxon_concept = taxon_concept

    respond_to do |format|
      format.html do
        show_taxa_html
      end
      format.xml do
        show_taxa_xml
      end
    end

  end

  # execute search and show results
  def search
    
    respond_to do |format|
      # TODO - please, please, PLEASE refactor this.  There is WAY too much going on in this controller.
      format.html do 
        current_user.content_level = params[:content_level] unless params[:content_level].nil?
        params[:search_language] ||= '*'
        params[:search_type] = EOLConvert.get_search_type(params[:search_type])
        params[:content_level] ||= '1'
        params[:q] ||= params[:id] ||= '' # allow search strings to be passed in as ID (Rails style) or as the "q" querystring param (Google style)
        
        params[:q].gsub!('_',' ') # convert underscores that might be used in friendly URLs into spaces
        
        last_published=HarvestEvent.last_published if params[:search_type].downcase == 'text' && allow_page_to_be_cached?
        @last_harvest_event_id=(last_published.blank? ? "0" : last_published.id.to_s)

         # this is a non-cached text search      
        if params[:search_type] == 'text' && (!allow_page_to_be_cached? || !read_fragment(:controller=>'taxa',:part=>'search_' + params[:search_language] + '_' + params[:q] + '_' + current_user.vetted.to_s + '_' + @last_harvest_event_id))

          @search = Search.new(params, request, current_user, current_agent)  
          @cached = false

          # TODO - There is a much better way to do this, please clean me - it is also duplicated in search.rb model  
          # if we have only one result, go straight to that page
          if @search.search_returned && @search.total_search_results == 1
            #taxon_concept_id = (@search.common_name_results[0][0] || @search.scientific_name_results[0][0] || @search.tag_results[0][0].id)
            taxon_concept_id = @search.common_results.empty? ? nil : @search.common_results[0][:id]
            taxon_concept_id = taxon_concept_id ? taxon_concept_id : (@search.scientific_results.empty? ? nil : @search.scientific_results[0][:id])
            taxon_concept_id = taxon_concept_id ? taxon_concept_id : (@search.tag_results.empty? ? nil: @search.tag_results[0][0].id)
            taxon_concept_id = taxon_concept_id ? taxon_concept_id : @search.suggested_searches[0].taxon_id
            redirect_to :controller => 'taxa', :action => 'show', :id => taxon_concept_id
          end

        elsif params[:search_type] == 'text' # this is a cached text search

          @search = Search.new(params,request,current_user,current_agent,false) # set up some variables needed on the page, but don't actually execute the search
          @cached = true

        elsif params[:search_type] == 'tag' # this is a tag search (which is never cached)

          @search = Search.new(params,request,current_user,current_agent)
          @cached = false

        else # this is a full-text serach (which is never cached)

          @search = Search.new(params,request,current_user,current_agent,false) # set up some variables needed on the page, but don't actually execute the search
          @cached=false

        end
      end
       format.xml do
          params[:search_language] ||= '*'
          # Not thrilled about this cache key, but we MUST detaint them, and it MUST include all criteria that affects
          # the search:
          if !params[:q].blank?
            key = "search/xml/#{params[:search_language].sub(/\*/, 'DEFAULT')}/#{params[:q].gsub(/[^-_A-Za-z0-9]/, '_')}"
            xml = Rails.cache.fetch(key, :expires_in => 8.hours) do
              results = TaxonConcept.quick_search(params[:q], :search_language => params[:search_language])
              xml_hash = {
                'taxon-pages' => (results[:scientific] + results[:common]).flatten.map { |r| TaxonConcept.find(r['id']) }
              }
              xml_hash['errors'] = XmlErrors.new(results[:errors]) unless results[:errors].nil?
              xml_hash.to_xml(:root => 'results')
            end
          else # user didn't send us any search parameter, so return a blank result
            xml=Hash.new.to_xml(:root => 'results')
          end
          render :xml => xml
        end
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

  def user_text_change_toc
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
    @taxon_concept.current_agent = current_agent unless current_agent.nil?
    @taxon_concept.current_user = current_user

    if (params[:data_objects_toc_category] && (toc_id = params[:data_objects_toc_category][:toc_id]))
      @toc_item = TocItem.find(toc_id)
    else
      @toc_item = tc.tocitem_for_new_text
    end

    @category_id = @toc_item.id    
    @ajax_update = true
    @content = @taxon_concept.content_by_category(@category_id)
    @new_text = render_to_string(:partial => 'content_body')
  end

  # AJAX: Render the requested content page
  def content

    if !request.xhr?
      render :nothing=>true
      return
    end

    @taxon_concept = TaxonConcept.find(params[:id]) 
    @category_id   = params[:category_id].to_i
    
    @taxon_concept.current_agent = current_agent unless current_agent.nil?
    @taxon_concept.current_user  = current_user
    @curator = @taxon_concept.current_user.can_curate?(@taxon_concept)

    @content     = @taxon_concept.content_by_category(@category_id)
    @ajax_update=true
    if @content.nil?
      render :text => '[content missing]'
    else
      @new_text_tocitem_id = get_new_text_tocitem_id(@category_id)
      render :update do |page|
        page.replace_html 'center-page-content', :partial => 'content.html.erb'
        page << "$('current_content').value = '#{@category_id}';"
        page << "Event.addBehavior.reload();"
        page << "EOL.TextObjects.update_add_links('#{url_for({:controller => :data_objects, :action => :new, :type => :text, :taxon_concept_id => @taxon_concept.id, :toc_id => @new_text_tocitem_id})}');"
        page['center-page-content'].set_style :height => 'auto'
      end      
    end

    log_data_objects_for_taxon_concept @taxon_concept, *@content[:data_objects] unless @content.nil?

  end

  # TODO - this param should really be taxon_concept_id, not taxon_id... but I feel like it will require changes to
  # Javascript, and I am not confident enough to change them right now.
  # AJAX: Render the requested image collection by taxon_id and page
  def image_collection

    if !request.xhr?
      render :nothing=>true
      return
    end  

    @image_page = (params[:image_page] ||= 1).to_i
    @taxon_concept = TaxonConcept.find(params[:taxon_id])
    @taxon_concept.current_user = current_user
    @taxon_concept.current_agent = current_agent
    start       = $MAX_IMAGES_PER_PAGE * (@image_page - 1)
    last        = start + $MAX_IMAGES_PER_PAGE - 1
    @images     = @taxon_concept.images[start..last]

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
      :taxon_id=>params[:taxon_concept_id],
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
      taxon_concept = params[:taxon_concept_id].to_i
      # log each data object ID specified (separate multiple with commas)
      params[:id].split(",").each { |id| log_data_objects_for_taxon_concept taxon_concept, DataObject.find_by_id(id.to_i) }
    end
    render :nothing => true
  end

  ###############################################
  protected

    # reset the content level if it is in the querystring NOTE the expertise level is set by pre filter
    # set_user_settings()
    def update_user_content_level
      current_user.content_level = params[:content_level] if ['1','2','3','4'].include?(params[:content_level])
    end

    # Set the page expertise and vetted defaults, get from querystring, update the session with this value if found
    def set_user_settings

      expertise = params[:expertise].to_sym if ['novice','middle','expert'].include?(params[:expertise])
      current_user.expertise=expertise unless expertise.nil?

      vetted = params[:vetted]
      current_user.vetted=EOLConvert.to_boolean(vetted) unless vetted.blank? 

      # save user in database if they are logged in
      current_user.save if logged_in?

    end

    def get_new_text_tocitem_id(category_id)
      if category_id && TocItem.find(category_id).allow_user_text?
        category_id
      else
        'none'
      end
    end
    
    def show_unvetted_videos
      vetted_mode = @taxon_concept.current_user.vetted
      @taxon_concept.current_user.vetted = false
      videos = @taxon_concept.videos unless @taxon_concept.videos.blank?
      @taxon_concept.current_user.vetted = vetted_mode
      return videos
    end
    
    def show_unvetted_videos #collect all videos (unvetted as well)
      vetted_mode = @taxon_concept.current_user.vetted
      @taxon_concept.current_user.vetted = false
      videos = @taxon_concept.videos unless @taxon_concept.videos.blank?
      @taxon_concept.current_user.vetted = vetted_mode
      return videos
    end
    
    def videos_to_show
      @videos = show_unvetted_videos # instant variable used in _mediacenter
      
      if params[:vet_flag] == "false"
        @video_collection = @videos            
      else 
        @video_collection = @taxon_concept.videos unless @taxon_concept.videos.blank?
      end
    end
    
    def taxon_concept
      tc_id = params[:id].to_i     
      if tc_id == 0
        # TODO: sensible redirect / message here
        raise "taxa id not supplied"
      else
        #begin
          taxon_concept = TaxonConcept.find(tc_id)
        #rescue
          ## TODO: sensible redirect / message here
          #raise "taxa does not exist"
        #end
      end
      return taxon_concept
    end

    # wich TOC item choose to show
    def show_category_id
      if params[:category_id].blank?
        show_category_id = first_content_item.nil? ? nil : first_content_item.id # by default use first TOC item
      else
        show_category_id = params[:category_id] # if page was called with &category_id=# - use it 
      end
    end
    
    def first_content_item
      # find first valid content area to use
      taxon_concept.table_of_contents(:vetted_only=>current_user.vetted, :agent_logged_in => agent_logged_in?).detect { |item| item.has_content? }
    end
    
    def this_request_is_really_a_search
      params[:id].to_i == 0
    end
    
    def do_the_search
      redirect_to :controller => 'taxa', :action => 'search', :id => params[:id]
    end
    
    def show_taxa_html
      
      update_user_content_level
      
      @taxon_concept.current_user = current_user

      if show_taxa_html_can_be_cached? or
         fragment_exist?(:controller => 'taxa', :part => taxa_page_html_fragment_name)
        @cached=true
      else
        @cached=false
        set_taxa_page_instance_vars
      end # end get full page since we couldn't read from cache

      render :template=>'/taxa/show_cached' if allow_page_to_be_cached? and not params[:category_id] # if caching is allowed, see if fragment exists using this template
    end

    def show_taxa_xml
      xml = Rails.cache.fetch("taxon.#{@taxon_concept.id}/xml", :expires_in => 4.hours) do
        @taxon_concept.to_xml(:full => true)
      end
      render :xml => xml
    end 
    
    def taxa_page_html_fragment_name
      current_user = @taxon_concept.current_user
      'page_' + params[:id].to_s + '_' + current_user.language_abbr + '_' + current_user.expertise.to_s + '_' + current_user.vetted.to_s + '_' + current_user.default_taxonomic_browser.to_s + '_' + @taxon_concept.show_curator_controls?.to_s
    end
    helper_method(:taxa_page_html_fragment_name)

    def show_taxa_html_can_be_cached?
      return(allow_page_to_be_cached? and 
             params[:category_id].blank? and
             params[:image_id].blank?)
    end

    # TODO - this smells like bad architecture.  The name of the method alone implies that we're doing something
    # wrong.  We really need some classes or helpers to take care of these details.
    def set_taxa_page_instance_vars
      @taxon_concept.current_agent = current_agent unless current_agent.nil?

      @images = @taxon_concept.images

      if(params[:image_id])
        image_id = params[:image_id].to_i
        selected_image_index = 0
        @images.each_with_index do |image,i|
          if image.id == image_id
            selected_image_index = i
            @selected_image = image
            break
          end
        end

        params[:image_page] = @image_page = ((selected_image_index+1) / $MAX_IMAGES_PER_PAGE.to_f).ceil

        @images = @images[((@image_page-1)*9)..((@image_page*9)-1)]
      else
        @selected_image = @images[0]
      end

      @video_collection = videos_to_show
      
      @category_id = show_category_id # need to be an instant var as we use it in several views and they use
                                      # variables with that name from different methods in different cases    
      @new_text_tocitem_id = get_new_text_tocitem_id(@category_id)

      @content     = @taxon_concept.content_by_category(@category_id) unless
        @category_id.nil? || @taxon_concept.table_of_contents(:vetted_only=>@taxon_concept.current_user.vetted).blank?
      @random_taxa = RandomHierarchyImage.random_set(5, @session_hierarchy)

      @data_object_ids_to_log = data_object_ids_to_log
    end

    # when a page is viewed (even a cached page), we want to know which data objects were viewed.  This method
    # builds that array, which later invokes an Ajax call.
    def data_object_ids_to_log
      ids = Array.new
      unless @images.blank?
        log_data_objects_for_taxon_concept @taxon_concept, @images.first
        ids << @images.first.id
      end
      unless @content.nil? || @content[:data_objects].blank?
        log_data_objects_for_taxon_concept @taxon_concept, *@content[:data_objects]
        @content[:data_objects].each {|data_object| ids << data_object.id }
      end
      return ids.compact
    end

end
