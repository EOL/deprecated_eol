class TaxaController < ApplicationController

  layout 'v2/taxa'

  prepend_before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN   # if we happen to be on an SSL page, go back to http

  def show
    if this_request_is_really_a_search
      do_the_search
      return
    end
    return redirect_to taxon_overview_path(params[:id]), :status => :moved_permanently
  end

  # If you want this to redirect to search, call (do_the_search && return if this_request_is_really_a_search) before this.
  def find_taxon_concept
    # Try most specific first...
    tc_id = params[:taxon_concept_id].to_i
    tc_id = params[:taxon_id].to_i if tc_id == 0
    tc_id = params[:id].to_i if tc_id == 0
    TaxonConcept.find(tc_id)
  end

  ################
  # AJAX CALLS
  ################

  def user_text_change_toc
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
    @taxon_concept.current_user = current_user

    if (params[:data_objects_toc_category] && (toc_id = params[:data_objects_toc_category][:toc_id]))
      @toc_item = TocEntry.new(TocItem.find(toc_id), :has_content => false)
    else
      @toc_item = TocEntry.new(@taxon_concept.tocitem_for_new_text, :has_content => false)
    end

    @category_id = @toc_item.category_id
    get_content_variables(:ajax_update => true)
    current_user.log_activity(:viewed_toc_id, :value => toc_id, :taxon_concept_id => @taxon_concept.id)
  end

  # AJAX: Render the requested content page
  def content

    if !request.xhr?
      render :nothing => true
      return
    end

    @taxon_concept = TaxonConcept.core_relationships(:only => [{:data_objects => :toc_items}, { :users_data_objects => { :data_object => :toc_items } }]).find(params[:id])
    @category_id   = params[:category_id].to_i

    @taxon_concept.current_user  = current_user
    @curator = current_user.min_curator_level?(:full)

    get_content_variables(:ajax_update => true)
    if @content.nil?
      render :text => '[content missing]'
      return true
    else
      @new_text_tocitem_id = get_new_text_tocitem_id(@category_id)
      current_user.log_activity(:viewed_content_for_category_id, :value => @category_id, :taxon_concept_id => @taxon_concept.id)
    end
  end

  def images
    taxon_concept = find_taxon_concept
    includes = { :top_concept_images => :data_object }
    selects = { :taxon_concepts => :supercedure_id,
      :data_objects => [ :id, :data_type_id, :data_subtype_id, :published, :guid, :data_rating ] }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(taxon_concept.id)
    @taxon_concept.current_user = current_user
    @image_page  = (params[:image_page] ||= 1).to_i
    start        = $MAX_IMAGES_PER_PAGE * (@image_page - 1)
    last         = start + $MAX_IMAGES_PER_PAGE - 1
    @images      = @taxon_concept.images(:image_page => @image_page)[start..last]
    @image_count = @taxon_concept.image_count
    set_selected_image
    current_user.log_activity(:viewed_page_of_images, :value => @image_page, :taxon_concept_id => @taxon_concept.id)
    render :partial => "images"
  end

  def maps
    @taxon_concept = find_taxon_concept
    render :partial => "maps"
  end

  def videos
    @taxon_concept = find_taxon_concept
    @taxon_concept.current_user = current_user
    @video_collection = videos_to_show
    render :layout => false
  end

  # AJAX: show the requested video
  def show_video

   if !request.xhr?
     render :nothing => true
     return
   end

    @data_object = DataObject.find(params[:data_object_id].to_i)
    current_user.log_activity(:viewed_video, :value => @data_object.object_cache_url)
    render :update do |page|
      page.replace_html 'video-player', :partial => 'data_objects/data_object_video'
    end
  end

  # AJAX: used to show a pop-up in a floating div, all views are in the "popups" subfolder
  def show_popup
    if !params[:name].blank? && request.xhr?
      template = params[:name]
      @taxon_name = params[:taxon_name] || "this taxon"
      render :layout => false, :template => 'popups/' + template
    else
      render :nothing => true
    end
  end

  def publish_wikipedia_article
    tc = TaxonConcept.find(params[:taxon_concept_id].to_i)
    data_object = DataObject.find(params[:data_object_id].to_i)
    data_object.publish_wikipedia_article(tc)

    category_id = params[:category_id].to_i
    redirect_url = "/pages/#{tc.id}"
    redirect_url += "?category_id=#{category_id}" unless category_id.blank? || category_id == 0
    current_user.log_activity(:published_wikipedia_article, :taxon_concept_id => tc.id)
    redirect_to redirect_url
  end

  def lookup_reference
    ref = Ref.find(params[:ref_id].to_i)
    callback = params[:callback]

    if defined? $REFERENCE_PARSING_ENABLED
      raise 'Reference parsing disabled' if !$REFERENCE_PARSING_ENABLED
    else
      parameter = SiteConfigurationOption.reference_parsing_enabled
      raise 'Reference parsing disabled' unless parameter && parameter.value == 'true'
    end

    if defined? $REFERENCE_PARSER_ENDPOINT
      endpoint = $REFERENCE_PARSER_ENDPOINT
    else
      endpoint_param = SiteConfigurationOption.reference_parser_endpoint
      endpoint = endpoint_param.value
    end

    if defined? $REFERENCE_PARSER_PID
      pid = $REFERENCE_PARSER_PID
    else
      pid_param = SiteConfigurationOption.reference_parser_pid
      pid = pid_param.value
    end

    raise 'Invalid configuration' unless pid && endpoint

    url = endpoint + "?pid=#{pid}&output=json&q=#{URI.escape(ref.full_reference)}&callback=#{callback}"
    render :text => Net::HTTP.get(URI.parse(url))
  end

private
  def instantiate_taxon_concept
    @taxon_concept = find_taxon_concept
    unless accessible_page?(@taxon_concept)
      if logged_in?
        raise EOL::Exceptions::SecurityViolation, "User with ID=#{current_user.id} does not have access to TaxonConcept with id=#{@taxon_concept.id}"
      else
        raise EOL::Exceptions::MustBeLoggedIn, "Non-authenticated user does not have access to TaxonConcept with ID=#{@taxon_concept.id}"
      end
    end
    @taxon_concept.current_user = current_user if @taxon_concept
    @selected_hierarchy_entry_id = params[:hierarchy_entry_id]
    if @selected_hierarchy_entry_id
      @selected_hierarchy_entry = HierarchyEntry.find_by_id(@selected_hierarchy_entry_id) rescue nil
      if @selected_hierarchy_entry.hierarchy.browsable?
        # TODO: Eager load hierarchy entry agents?
        @browsable_hierarchy_entries = @taxon_concept.published_hierarchy_entries.select{ |he| he.hierarchy.browsable? }
      else
        @selected_hierarchy_entry = nil
      end
    end
  end

  def promote_exemplar(data_objects)
    if @taxon_concept.blank? || @taxon_concept.taxon_concept_exemplar_image.blank?
      exemplar_image = data_objects[0] unless data_objects.blank?
    else
      exemplar = @taxon_concept.taxon_concept_exemplar_image
      exemplar_image = exemplar.data_object unless exemplar.nil?
    end
    unless exemplar_image.nil?
      data_objects.delete_if{ |d| d.guid == exemplar_image.guid }

      # Get the latest version of the exemplar image
      latest_published_exemplar_image = DataObject.latest_published_version_of(exemplar_image.id)
      exemplar_image = latest_published_exemplar_image unless latest_published_exemplar_image.nil?

      data_objects.unshift(exemplar_image)
    end
    data_objects
  end

  def redirect_if_superceded
    if @taxon_concept.superceded_the_requested_id?
      redirect_to url_for(:controller => params[:controller], :action => params[:action], :taxon_id => @taxon_concept.id), :status => :moved_permanently
      return false 
    end
  end

  def get_content_variables(options = {})
    @content = @taxon_concept.content_by_category(@category_id, :current_user => current_user, :hierarchy_entry => options[:hierarchy_entry])
    @whats_this = @content[:category_name].blank? ? "" : WhatsThis.get_url_for_name(@content[:category_name])
    @ajax_update = options[:ajax_update]
    @languages = build_language_list if is_common_names?(@category_id)
  end

  def update_user_content_level
    current_user.content_level = params[:content_level] if ['1','2','3','4'].include?(params[:content_level])
  end

  def add_page_view_log_entry
    PageViewLog.create(:user => current_user, :agent => current_user.agent, :taxon_concept => @taxon_concept)
  end

  def get_new_text_tocitem_id(category_id)
    if category_id && toc = TocItem.find_by_id(category_id)
      return category_id if toc.allow_user_text?
    end
    return 'none'
  end

  def videos_to_show
    @default_videos = @taxon_concept.video_data_objects
    @videos = show_unvetted_videos

    if params[:vet_flag] == "false"
      @video_collection = @videos
    else
      @video_collection = @default_videos unless @default_videos.blank?
    end
  end

  # collect all videos (unvetted as well)
  def show_unvetted_videos
    videos = @taxon_concept.video_data_objects(:unvetted => true) unless @default_videos.blank?
    return videos
  end

  def this_request_is_really_a_search
    tc_id = params[:id].to_i
    tc_id = params[:taxon_id].to_i if tc_id == 0
    tc_id == 0
  end

  def do_the_search
    redirect_to search_path(:id => params[:id])
  end

  def taxa_page_cache_fragment_name
    return {
      :controller => '/taxa',
      :part => "page_#{@taxon_concept.id}_#{@section}_#{@taxon_concept.current_user.taxa_page_cache_str}_#{@taxon_concept.show_curator_controls?}"
    }
  end
  helper_method(:taxa_page_cache_fragment_name)

  def show_taxa_html_can_be_cached?
    return(allow_page_to_be_cached? and
           params[:category_id].blank? and
           params[:image_id].blank?)
  end

  def find_selected_image_index(images, image_id)
    image_to_find = DataObject.find_by_id(image_id)
    return nil if image_to_find.blank?
    images.each_with_index do |image, index|
      if image.guid == image_to_find.guid
        return index
      end
    end
    return nil
  end

  # Image ID could have been superceded (by, say, a newer version of the same image), so we need to normalize it.
  def set_selected_image
    if(params[:image_id])
      latest_published_image = DataObject.latest_published_version_of(params[:image_id].to_i)
      unless latest_published_image
        flash[:warning] = I18n.t("image_not_found")
        return
      end
      image_id = latest_published_image.id

      selected_image_index = find_selected_image_index(@images,image_id)
      if selected_image_index.nil?
        @taxon_concept.current_user = current_user
        selected_image_index = find_selected_image_index(@images,image_id)
      end
      unless selected_image_index
        flash[:warning] = I18n.t("image_is_no_longer_available")
        return
      end
      params[:image_page] = @image_page = ((selected_image_index+1) / $MAX_IMAGES_PER_PAGE.to_f).ceil
      start        = $MAX_IMAGES_PER_PAGE * (@image_page - 1)
      last         = start + $MAX_IMAGES_PER_PAGE - 1
      @images      = @taxon_concept.images(:image_page=>@image_page)[start..last]
      adjusted_selected_image_index = selected_image_index % $MAX_IMAGES_PER_PAGE
      @selected_image_id = @images[adjusted_selected_image_index].id
    else
      @selected_image_id = @images[0].id unless @images.blank?
    end
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

  def is_common_names?(category_id)
    TocItem.common_names.id == category_id
  end

  def build_language_list
    current_user_copy = current_user.dup || nil
    @languages = Language.with_iso_639_1.map do |lang|
      { :label    => lang.label,
        :id       => lang.id,
        :selected => lang.id == (current_user_copy && current_user_copy.language_id) ? "selected" : nil
      }
    end
  end

  def log_action(tc, object, method)
    auto_collect(tc) # SPG asks for all curation (including names) to add the item to their watchlist.
    CuratorActivityLog.create(
      :user => current_user,
      :changeable_object_type => ChangeableObjectType.send(object.class.name.underscore.to_sym),
      :object_id => object.id,
      :activity => Activity.send(method),
      :data_object => @data_object,
      :taxon_concept => tc,
      :created_at => 0.seconds.from_now
    )
  end

end
