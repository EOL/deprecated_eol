class TaxaController < ApplicationController

  layout 'v2/taxa'

  prepend_before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN   # if we happen to be on an SSL page, go back to http
  before_filter :set_session_hierarchy_variable, :only => [:show, :classification_attribution, :content, :curators]
  after_filter :set_meta_description_and_keys

  # this is cheating because of mixing taxon and taxon concept use of the controller
  def index
    # you need to be a content partner OR ADMIN and logged in to get here
    if !current_user.is_content_partner? && !current_user.is_admin?
      return redirect_to(root_url)
    end

    if params[:harvest_event_id] && params[:harvest_event_id].to_i > 0
      page = params[:page] || 1
      @harvest_event = HarvestEvent.find(params[:harvest_event_id])
      @taxa_contributed = @harvest_event.taxa_contributed(params[:harvest_event_id]).all_hashes.uniq.paginate(:page => page)
      @page_title = $ADMIN_CONSOLE_TITLE if current_user.is_admin?
      @navigation_partial = '/admin/navigation'
      render :html => 'content_partner', :layout => current_user.is_admin? ? 'left_menu' : 'content_partner'
    else
      redirect_to(:action=>:show, :id => params[:id])
    end
  end

  def show
    if this_request_is_really_a_search
      do_the_search
      return
    end
    taxon_id = params[:id] if params[:id]
    return redirect_to taxon_overview_path(taxon_id)
  end

  # a permanent redirect to the new taxon_concept page
  def taxa
    headers["Status"] = "301 Moved Permanently"
    redirect_to(params.merge(:controller => 'taxa', :action => 'show', :id => HierarchyEntry.find(params[:id]).taxon_concept_id))
  end

  # If you want this to redirect to search, call (do_the_search && return if this_request_is_really_a_search) before this.
  def find_taxon_concept
    tc_id = params[:id].to_i
    tc_id = params[:taxon_id].to_i if tc_id == 0
    tc_id = params[:taxon_concept_id].to_i if tc_id == 0
    redirect_to_missing_page_on_error do
      TaxonConcept.find(tc_id)
    end
  end

  def taxon_concept_invalid?(tc)
    redirect_to_missing_page_on_error do
      raise "TaxonConcept not found" if tc.nil?
      raise "Page not accessible" unless accessible_page?(tc)
    end
  end

  def classification_attribution
    @taxon_concept = find_taxon_concept
    return if taxon_concept_invalid?(@taxon_concept)
    current_user.log_activity(:viewed_classification_attribution_on_taxon_concept, :taxon_concept_id => @taxon_concept.id)
    render :partial => 'classification_attribution', :locals => {:taxon_concept => @taxon_concept}
  end

  # page that will allows a non-logged in user to change content settings
  def settings

    store_location(params[:return_to]) if !params[:return_to].nil? # store the page we came from so we can return there if it's passed in the URL

    # grab logged in user
    @user = current_user

    # if the user is logged in, they should be at the profile page
    if logged_in?
      if params[:from_taxa_page].blank?
        return redirect_to(profile_url)
      else
        @user.update_attributes(params[:user])
        params[:from_taxa_page]
      end
    end

    unless request.post? # first time on page, get current settings
      # set expertise to a string so it will be picked up in web page controls
      @user.expertise = current_user.expertise.to_s
      @page_title = I18n.t(:your_preferences)
      render(:layout => 'v2/basic')
      return
    end
    alter_current_user do |u|
      u.update_attributes(params[:user])
    end
    @user = current_user
    flash[:notice] =  I18n.t(:your_preferences_have_been_updated)  if params[:from_taxa_page].blank?
    store_location(EOLWebService.uri_remove_param(return_to_url, 'vetted')) if valid_return_to_url
    redirect_back_or_default
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
    return if taxon_concept_invalid?(taxon_concept)
    includes = { :top_concept_images => :data_object }
    selects = { :taxon_concepts => :supercedure_id,
      :data_objects => [ :id, :data_type_id, :published, :guid, :data_rating ] }
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
    return if taxon_concept_invalid?(@taxon_concept)
    render :partial => "maps"
  end

  def videos
    @taxon_concept = find_taxon_concept
    return if taxon_concept_invalid?(@taxon_concept)
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

  # Ajax method to change the preferred name on a Taxon Concept:
  # TODO - This needs to add a CuratorActivityLog.
  def update_common_names
    tc = find_taxon_concept
    return if taxon_concept_invalid?(tc)
    if current_user.min_curator_level?(:full)
      if !params[:preferred_name_id].nil?
        name = Name.find(params[:preferred_name_id])
        language = Language.find(params[:language_id])
        tc.add_common_name_synonym(name.string, :agent => current_user.agent, :language => language, :preferred => 1,
                                   :vetted => Vetted.trusted)
        expire_taxa([tc.id])
      end

      if params[:trusted_name_clicked_on] != "false"
        if params[:trusted_name_checked] == "true"
          name = Name.find(params[:trusted_name_clicked_on])
          language = Language.find(params[:language_id])
          tc.add_common_name_synonym(name.string, :agent => current_user.agent, :language => language,
                                     :vetted => Vetted.trusted, :preferred => 0)
          expire_taxa([tc.id])
        elsif params[:trusted_synonym_clicked_on] != "false"
          tcn = TaxonConceptName.find_by_synonym_id_and_taxon_concept_id(params[:trusted_synonym_clicked_on], tc.id)
          tc.delete_common_name(tcn)
          expire_taxa([tc.id])
        end
      end
      current_user.log_activity(:updated_common_names, :taxon_concept_id => tc.id)
    end
    if !params[:hierarchy_entry_id].blank?
      redirect_to common_names_taxon_hierarchy_entry_names_path(tc, params[:hierarchy_entry_id])
    else
      redirect_to common_names_taxon_names_path(tc)
    end
  end

#  # TODO - This needs to add a CuratorActivityLog.
#  def add_common_name
#    tc = TaxonConcept.find(params[:taxon_concept_id])
#    if params[:name][:name_string] && params[:name][:name_string].strip != ""
#      agent = current_user.agent
#      language = Language.find(params[:name][:language])
#      if current_user.is_curator?
#        synonym = tc.add_common_name_synonym(params[:name][:name_string], :agent => agent, :language => language,
#                                             :vetted => Vetted.trusted)
#        log_action(tc, synonym, :add_common_name)
#      else
#        flash[:error] = I18n.t(:insufficient_privileges_to_add_common_name)
#      end
#      expire_taxa([tc.id])
#    end
#    if !params[:hierarchy_entry_id].blank?
#      redirect_to common_names_taxon_hierarchy_entry_names_path(tc, params[:hierarchy_entry_id])
#    else
#      redirect_to common_names_taxon_names_path(tc)
#    end
#  end

  # TODO - This needs to add a CuratorActivityLog.
  def delete_common_name
    tc = TaxonConcept.find(params[:taxon_concept_id].to_i)
    synonym_ids = params[:synonym_ids].map {|s| s.to_i}.uniq
    category_id = params[:category_id].to_i
    synonym_ids.each do |synonym_id|
      tcn = TaxonConceptName.find_by_synonym_id_and_taxon_concept_id(synonym_id, tc.id)
      tc.delete_common_name(tcn)
      log_action(tc, tcn, :remove_common_name) if tc && tcn
    end
    if !params[:hierarchy_entry_id].blank?
      redirect_to common_names_taxon_hierarchy_entry_names_path(tc, params[:hierarchy_entry_id])
    else
      redirect_to common_names_taxon_names_path(tc)
    end
  end

  # TODO - This needs to add a CuratorActivityLog.
  def vet_common_name
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id].to_i)
    language_id = params[:language_id].to_i
    name_id = params[:name_id].to_i
    vetted = Vetted.find(params[:vetted_id])
    @taxon_concept.current_user = current_user
    @taxon_concept.vet_common_name(:language_id => language_id, :name_id => name_id, :vetted => vetted)
    current_user.log_activity(:vetted_common_name, :taxon_concept_id => @taxon_concept.id, :value => name_id)
    if !params[:hierarchy_entry_id].blank?
      redirect_to common_names_taxon_hierarchy_entry_names_path(@taxon_concept, params[:hierarchy_entry_id])
    else
      redirect_to common_names_taxon_names_path(@taxon_concept)
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

  def curators
    # if this is named taxon_concept then the RSS feeds will be added to the page
    # in Firefox those feeds are evaluated when the pages loads, so this should save some queries
    @concept = find_taxon_concept
    return if taxon_concept_invalid?(@concept)
    @page_title = I18n.t(:curators_of_taxon_page_title, :taxon => @concept.title(@session_hierarchy))
    curators = @concept.curators(:add_names => true)
    @curators = User.find_all_by_id(curators.collect{ |c| c.id })
    @curators = User.sort_by_name(@curators)
    render(:layout => 'v2/basic')
  end

private
  def instantiate_taxon_concept
    @taxon_concept = find_taxon_concept
    # TODO: is this the best name for this?
    @selected_hierarchy_entry_id = params[:hierarchy_entry_id]
    if @selected_hierarchy_entry_id
      @selected_hierarchy_entry = HierarchyEntry.find_by_id(@selected_hierarchy_entry_id) rescue nil
      # TODO: Eager load hierarchy entry agents?
      @browsable_hierarchy_entries = @taxon_concept.published_hierarchy_entries.select{ |he| he.hierarchy.browsable? }
    end
  end

  def promote_exemplar(data_objects)
    return data_objects if @taxon_concept.blank? || data_objects.blank? || @taxon_concept.taxon_concept_exemplar_image.blank?
    exemplar = @taxon_concept.taxon_concept_exemplar_image
    if exemplar && exemplar_image = exemplar.data_object
      data_objects.delete_if{ |d| d.id == exemplar_image.id }
      data_objects.unshift(exemplar_image)
    end
    data_objects
  end

  def redirect_if_invalid
    redirect_to_missing_page_on_error do
      raise "TaxonConcept not found" if @taxon_concept.nil?
      raise "Page not accessible" unless accessible_page?(@taxon_concept)
    end
  end

  def redirect_if_superceded
    redirect_to taxon_overview_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
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

  # wich TOC item choose to show
  def show_category_id
    if params[:category_id] && !params[:category_id].blank?
      params[:category_id]
    elsif !(first_content_item = @taxon_concept.table_of_contents(:vetted_only => current_user.vetted, :agent_logged_in => agent_logged_in?).detect {|item| item.has_content? }).nil?
      first_content_item.category_id
    else
      nil
    end
  end

  def first_content_item
    # find first valid content area to use
    @taxon_concept.table_of_contents(:vetted_only => current_user.vetted, :agent_logged_in => agent_logged_in?).detect { |item| item.has_content? }
  end

  def handle_whats_this
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
        current_user.vetted = false
        current_user.save if logged_in?

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
    @languages = Language.with_iso_639_1.map  do |lang|
      {
        :label    => lang.label,
        :id       => lang.id,
        :selected => lang.id == (current_user_copy && current_user_copy.language_id) ? "selected" : nil
      }
    end
  end

  def set_meta_description_and_keys
    if @taxon_concept
      @meta_description = "#{@taxon_concept.title} (#{@taxon_concept.subtitle}) in Encyclopedia of Life"
      @meta_keywords = @taxon_concept.title + " " + @taxon_concept.subtitle
    end
  end

  def log_action(tc, object, method)
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
