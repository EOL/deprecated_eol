class TaxaController < ApplicationController

  layout 'main'
  prepend_before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN   # if we happen to be on an SSL page, go back to http
  before_filter :set_session_hierarchy_variable, :only => [:show, :classification_attribution]

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

    unless accessible_page?(@taxon_concept)
      render(:layout => 'main', :template => "content/missing", :status => 404)
      return
    end

    redirect_to(params.merge(:controller => 'taxa',
                             :action => 'show',
                             :id => @taxon_concept.id,
                             :status => :moved_permanently)) if
      @taxon_concept.superceded_the_requested_id?

    respond_to do |format|
      format.html do
        show_taxa_html
      end
      format.xml do
        show_taxa_xml
      end
    end

  end

  def classification_attribution
    @taxon_concept = taxon_concept
    render :partial => 'classification_attribution', :locals => {:taxon_concept => taxon_concept}
  end

  # TODO - log that a search was performed
  def search
    @querystring = params[:q] || params[:id]
    @search_type = params[:search_type] || 'text'
    @page_title = "EOL Search: #{@querystring}"
    if @search_type == 'google'
      render :html => 'google_search'
    elsif @search_type == 'tag'
      search_tag
    else
      search_text
    end
    @suggested_results  = append_search_results_from_db(@querystring, @suggested_results,  :type => :suggested)
    @common_results     = append_search_results_from_db(@querystring, @common_results,     :type => :common)
    @scientific_results = append_search_results_from_db(@querystring, @scientific_results, :type => :scientific)
  end

  def search_tag
    @search = Search.new(params, request, current_user, current_agent)
    results = @search.search_results[:tags].map do |tag_result|
      tc = tag_result[0]
      dato = tag_result[1]
      {'taxon_concept_id' => [tc.id],
       'vetted_id'        => [tc.vetted_id],
       'preferred_scientific_name' => [tc.scientific_name],
       'common_name'      => [tc.common_name],
       'top_image_id'     => dato.id }
    end
    results = results
    if current_user.expertise.to_s == 'expert'
      @scientific_results = results.paginate(:page => 1, :per_page => results.length + 1, :total_entries => results.length)
      @common_results = [].paginate(:page => 1, :per_page => 10, :total_entries => 0)
    else 
      @scientific_results = [].paginate(:page => 1, :per_page => 10, :total_entries => 0)
      @common_results = results.sort_by {|tc| tc['common_name'] }.paginate(:page => 1, :per_page => results.length + 1, :total_entries => results.length) 
    end
    @suggested_results = [].paginate(:page => 1, :per_page => 10, :total_entries => 0)
    @all_results = results
  end

  def search_text
    if @querystring.blank?
      @all_results = [].paginate(:page => 1, :per_page => 10, :total_entries => 0)
    else
      @suggested_results  = SearchSuggestion.find_all_by_term_and_active(@querystring, true, :order=>'sort_order')
      suggested_results_query = @suggested_results.select {|i| i.taxon_id.to_i > 0}.map {|i| 'taxon_concept_id:' + i.taxon_id}.join(' OR ')
      suggested_results_query = suggested_results_query.blank? ? "taxon_concept_id:0" : "(#{suggested_results_query})"
      
      @suggested_results  = TaxonConcept.search_with_pagination(suggested_results_query, params)
      @scientific_results = TaxonConcept.search_with_pagination(prepare_solr_querystring(@querystring,'preferred_scientific_name'), params) # Pass params for pagination?
      @common_results     = TaxonConcept.search_with_pagination(prepare_solr_querystring(@querystring,'common_name'), params) # Pass params for pagination?
      
      @all_results = (@suggested_results + @scientific_results + @common_results)
    end
    respond_to do |format|
      format.html do 
        redirect_to_taxa_page(@all_results) if (@all_results.length == 1 and not params[:page].to_i > 1)
      end
      format.xml do
        if @all_results.blank?
          xml = Hash.new.to_xml(:root => 'results')
        else
          key = "search/xml/#{@querystring.gsub(/[^-_A-Za-z0-9]/, '_')}"
          xml = Rails.cache.fetch(key, :expires_in => 8.hours) do
            xml_hash = {
              'suggested-results'  => @suggested_results.map { |r| TaxonConcept.find(r['taxon_concept_id']) },
              'scientific-results' => @scientific_results.map { |r| TaxonConcept.find(r['taxon_concept_id']) },
              'common-results'     => @common_results.map { |r| TaxonConcept.find(r['taxon_concept_id']) }
            }
            # TODO xml_hash['errors'] = XmlErrors.new(results[:errors]) unless results[:errors].nil?
            xml_hash.to_xml(:root => 'results')
          end
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
      @toc_item = TocEntry.new(TocItem.find(toc_id), :has_content => false)
    else
      @toc_item = TocEntry.new(@taxon_concept.tocitem_for_new_text, :has_content => false)
    end

    @category_id = @toc_item.category_id    
    @ajax_update = true
    @content = @taxon_concept.content_by_category(@category_id,:current_user=>current_user)
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

    @content     = @taxon_concept.content_by_category(@category_id,:current_user=>current_user)
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
      @selected_image = @images[0]
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

  # Ajax method to change the preferred name on a Taxon Concept:
  def set_preferred_name
    tc = taxon_concept
    if tc.is_curatable_by?(current_user)
      tc.set_preferred_name(current_user.language, params[:name_id].to_i)
      expire_taxa(tc.id)
    end
    render :nothing => true
  end

###############################################
private

  # TODO: Get rid of the content level, it is depracated and no longer needed
  # set_user_settings()
  def update_user_content_level
    current_user.content_level = params[:content_level] if ['1','2','3','4'].include?(params[:content_level])
  end

  def get_new_text_tocitem_id(category_id)
    if category_id && TocItem.find(category_id).allow_user_text?
      category_id
    else
      'none'
    end
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
    tc_id = params[:taxon_concept_id].to_i if tc_id == 0
    if tc_id == 0
      # TODO: sensible redirect / message here
      raise "taxa id not supplied"
    else
      begin
        taxon_concept = TaxonConcept.find(tc_id)
      rescue
        return nil
      end
    end
    return taxon_concept
  end

  # wich TOC item choose to show
  def show_category_id
    if params[:category_id] && !params[:category_id].blank?
      params[:category_id]
    elsif !(first_content_item = @taxon_concept.table_of_contents(:vetted_only=>current_user.vetted, :agent_logged_in => agent_logged_in?).detect {|item| item.has_content? }).nil?
      first_content_item.category_id
    else
      nil
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

    if show_taxa_html_can_be_cached? &&
       fragment_exist?(:controller => 'taxa', :part => taxa_page_html_fragment_name)
      @cached=true
    else
      @cached=false
      failure = set_taxa_page_instance_vars
      return false if failure
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
    return "page_#{params[:id]}_#{current_user.taxa_page_cache_str}_#{@taxon_concept.show_curator_controls?}"
  end
  helper_method(:taxa_page_html_fragment_name)

  def show_taxa_html_can_be_cached?
    return(allow_page_to_be_cached? and 
           params[:category_id].blank? and
           params[:image_id].blank?)
  end

  def find_selected_image_index(images,image_id)
    images.each_with_index do |image,i|
      if image.id == image_id
        return i
      end
    end
    return nil
  end

  def set_image_permalink_data
    if(params[:image_id])
      image_id = params[:image_id].to_i
      selected_image_index = 0

      selected_image_index = find_selected_image_index(@images,image_id)
      if selected_image_index.nil?
        current_user.vetted=false
        current_user.save if logged_in?

        @taxon_concept.current_user = current_user
        @images = @taxon_concept.images

        selected_image_index = find_selected_image_index(@images,image_id)
      end
      if selected_image_index.nil?
        raise 'Image not found'
      end
      @selected_image = @images[selected_image_index]

      params[:image_page] = @image_page = ((selected_image_index+1) / $MAX_IMAGES_PER_PAGE.to_f).ceil

      @images = @images[((@image_page-1)*9)..((@image_page*9)-1)]
    else
      @selected_image = @images[0]
    end
  end

  def set_text_permalink_data
    if(params[:text_id])
      text_id = params[:text_id].to_i

      @selected_text = DataObject.find_by_id(text_id)

      if @selected_text && @selected_text.taxon_concepts.include?(@taxon_concept) && (@selected_text.visible? || (@selected_text.invisible? && current_user.can_curate?(@selected_text)) || (@selected_text.inappropriate? && current_user.is_admin?))
        selected_toc = @selected_text.toc_items[0]

        params[:category_id] = selected_toc.id

        @category_id = show_category_id

        if current_user.vetted && (@selected_text.untrusted? || @selected_text.unknown?)
          current_user.vetted = false
          current_user.save if logged_in?
        end
      else
        raise 'Text not found'
      end
    end
  end

  def set_image_comment_permalink_data
    if params[:image_id].nil? && params[:image_comment_id]
      comment_id = params[:image_comment_id].to_i

      comment = Comment.find_by_id(comment_id)

      if comment && comment.parent_type == 'DataObject'
        data_object = DataObject.find(comment.parent_id)
        if data_object.taxon_concepts.include?(@taxon_concept) && data_object.image?
          params[:image_id] = data_object.id

          set_image_permalink_data

          @selected_image_comment = comment

          set_comment_permalink_pagination(data_object.id, comment)
        else
          raise "No image with id #{data_object.id} for taxon concept with id #{@taxon_concept.id} or not of type image"
        end
      else
        raise "Comment not for a data object"
      end
    end
  end


  def set_text_comment_permalink_data
    if params[:text_id].nil? && params[:text_comment_id]
      comment_id = params[:text_comment_id].to_i

      comment = Comment.find(comment_id)

      if comment.parent_type == 'DataObject'
        data_object = DataObject.find(comment.parent_id)
        if data_object.taxon_concepts.include?(@taxon_concept) && data_object.text?
          params[:text_id] = data_object.id

          set_text_permalink_data

          @selected_text_comment = comment

          set_comment_permalink_pagination(data_object.id, comment)
        else
          raise "No text with id #{data_object.id} for taxon concept with id #{@taxon_concept.id} or not of type text"
        end
      else
        raise "Comment not for a data object"
      end
    end
  end
  
  def set_comment_permalink_pagination(data_object_id, comment)

    all_comments = Comment.find_all_by_parent_id_and_parent_type(data_object_id, 'DataObject')

    comment_index = nil
    all_comments.each_with_index do |c, i|
      if c == comment
        comment_index = i
        break
      end
    end

    @comment_page = ((comment_index).to_f / 10).floor + 1
  end

  def set_comment_permalink_data
    if params[:comment_id]
      @comment = Comment.find(params[:comment_id].to_i)
      if @comment.parent_id != @taxon_concept.id || @comment.parent_type != 'TaxonConcept'
        raise 'Comment not for this species'
      end
    end
  end

  # TODO - this smells like bad architecture.  The name of the method alone implies that we're doing something
  # wrong.  We really need some classes or helpers to take care of these details.
  def set_taxa_page_instance_vars
    @taxon_concept.current_agent = current_agent unless current_agent.nil?

    @images = @taxon_concept.images

    begin
      set_comment_permalink_data
      set_image_permalink_data
      set_text_permalink_data
      set_image_comment_permalink_data
      set_text_comment_permalink_data
    rescue
      render_404
      return true
    end

    @video_collection = videos_to_show
    
    @category_id = show_category_id # need to be an instant var as we use it in several views and they use
                                    # variables with that name from different methods in different cases

    @new_text_tocitem_id = get_new_text_tocitem_id(@category_id)

    @content     = @taxon_concept.content_by_category(@category_id,:current_user=>current_user) unless
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

  # For regular users, a page is accessible only if the taxon_concept is published.
  # If an agent is logged in, then it's only accessible if the taxon_concept is 
  # referenced by the Agent's most recent harvest events
  def accessible_page?(taxon_concept)
    return false if taxon_concept.nil?      # TC wasn't found.
    return true if taxon_concept.published? # Anyone can see published TCs
    return true if agent_logged_in? and current_agent.latest_unpublished_harvest_contains?(taxon_concept.id)
    return false # current agent can't see this unpublished page, or agent isn't logged in.
  end

  def allow_text_search_to_be_cached?
    text_search? and allow_page_to_be_cached?
  end

  def text_search?
    params[:search_type].downcase == 'text'
  end

  def search_fragment_name(lang, query, page)
    page ||= 1
    {:controller => 'taxa',
     :part => "search_#{lang}_#{query}_#{page}_#{current_user.vetted}_#{@last_harvest_event_id}"}
  end
  helper_method(:search_fragment_name)

  def redirect_to_taxa_page(result_set)
    redirect_to :controller => 'taxa', :action => 'show', :id => result_set.first['taxon_concept_id']
  end

  def append_search_results_from_db(querystring, search_results, options = {})
    return nil unless search_results
    search_results.each do |res|
      tc = TaxonConcept.find(res['taxon_concept_id'][0])
      res.merge!({
        'title' => tc.title(@session_hierarchy),
        'preferred_common_name' => (tc.common_name(@session_hierarchy) || '')
        })
      if options[:type] == :common # Common name search, we want to show them the best matched common name:
        find_matched_common_name(querystring, res)
      else
        res.merge!('best_matched_common_name' => res['preferred_common_name']) # Show them the preferred name
      end
    end
  end

  # TODO - this doesn't belong here.  We need a class for these result sets, and it belongs there.
  def find_matched_common_name(original_querystring, search_result)
    common_names = search_result['common_name'].clone
    querystring  = normalize_name(original_querystring).split(' ').to_set
    if common_names # TODO - this else clause is really a separate method to "repair" missing common names
      # TODO - this smells like a class method:
      common_names.map! do |name|
        name_set  = normalize_name(name).split(' ').to_set
        intersect = name_set.intersection(querystring) # TODO - make sure querystring members are all downcased.
        [name, intersect.size]
      end
      common_names = common_names.sort_by {|i| i[1]}.reverse 
      # if we have only 0s, return the preferred name:
      if common_names.first[1] == 0
        search_result['best_matched_common_name'] = search_result['preferred_common_name']
      else
        # if the best matches *include* the preferred name, use that:
        best_matches = common_names.find_all {|i| i[1] == common_names.first[1]}.map {|i| i[0] }
        if best_matches.include?(normalize_name(search_result['preferred_common_name']))
          search_result['best_matched_common_name'] = search_result['preferred_common_name']
        else # Otherwise, just use the best match:
          search_result['best_matched_common_name'] = common_names.first[0]
        end
      end
    else # Common names were bogus:
      search_result['common_name'] = ['']
      search_result['best_matched_common_name'] = ''
    end
  end

  def normalize_name(name)
    @@normalization_regex ||= /[;:,\.\(\)\[\]\!\?\*_\\\/\"\']/
    @@spaces_regex        ||= /\s+/
    return name.downcase.gsub(@@normalization_regex, '').gsub(@@spaces_regex, ' ')
  end

  def prepare_solr_querystring(query, field)
    literal_query = "#{field}:\"#{query}\""
    query = query.gsub /\s+/, ' '
    query = query.split(' ').map {|w| "+#{w}"}.join(' ')
    query = "(#{literal_query})" #OR #{field}:(#{query}))"
  end


end
