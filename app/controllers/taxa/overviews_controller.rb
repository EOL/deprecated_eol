class Taxa::OverviewsController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    
    
    # if(params[:he_id])
    #   he = HierarchyEntry.find_by_id(params[:he_id])
    # end  
    
    
    includes = [
      { :published_hierarchy_entries => [ :name , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => { :toc_items => :info_items } },
      { :top_concept_images => :data_object },
      { :curator_activity_logs => :user },
      { :users_data_objects => { :data_object => :toc_items } }]
    selects = {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :names => [ :string, :italicized, :canonical_form_id ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :hierarchies_content => [ :content_level, :image, :text, :child_image, :map, :youtube, :flash ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :vetted_id, :visibility_id, :published, :guid, :data_rating ],
      :table_of_contents => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name, :logo_cache_url, :tag_line ] }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)

    toc_items = [TocItem.brief_summary, TocItem.comprehensive_description, TocItem.distribution]
    options = { :limit => 1 }
    @summary_text = @taxon_concept.text_objects_for_toc_items(toc_items, options)

    @dropdown_hierarchy_entry_id = params[:he_id] || ""
    @dropdown_hierarchy_entry = HierarchyEntry.find_by_id(@dropdown_hierarchy_entry_id) || nil;

    
    @media = promote_exemplar(@taxon_concept.media({}, @dropdown_hierarchy))

    @watch_collection = logged_in? ? current_user.watch_collection : nil

    @assistive_section_header = I18n.t(:assistive_overview_header)

    #@concept_browsable_hierarchies = Hierarchy.browsable_for_concept(@taxon_concept)
    #@all_browsable_hierarchies = Hierarchy.browsable_by_label
    
    # there is where we can set it to ALL hierarchies, or only for this node
    #@hierarchies_to_offer = @all_browsable_hierarchies.dup
    #@hierarchies_to_offer = Hierarchy.all.dup
    @hierarchy_entries_to_offer = @taxon_concept.published_browsable_hierarchy_entries #todo should be published, and h are browsable
    
    #debugger
    
    # add the user's hierarchy in case the current concept is it
    # we'll need to default the list to the user's hierarchy no matter what
    # @hierarchies_to_offer << @session_hierarchy
    # @hierarchies_to_offer = @hierarchies_to_offer.uniq.sort_by{|h| h.form_label}

    
  
    current_user.log_activity(:viewed_taxon_concept_overview, :taxon_concept_id => @taxon_concept.id)

  end

  # # page that will allows a non-logged in user to change content settings
  # def settings
  #   #debugger
  #   store_location(params[:return_to]) if !params[:return_to].nil? # store the page we came from so we can return there if it's passed in the URL
  #   # grab logged in user
  #   @user = current_user
  #   # if the user is logged in, they should be at the profile page
  #   if logged_in?
  #     if params[:from_taxa_page].blank?
  #       return redirect_to(profile_url)
  #     else
  #       @user.update_attributes(params[:user])
  #       params[:from_taxa_page]
  #     end
  #   end
  #   unless request.post? # first time on page, get current settings
  #     # set expertise to a string so it will be picked up in web page controls
  #     @user.expertise = current_user.expertise.to_s
  #     @page_title = I18n.t(:your_preferences)
  #     render(:layout => 'v2/basic')
  #     return
  #   end
  #   alter_current_user do |u|
  #     u.update_attributes(params[:user])
  #   end
  #   @user = current_user
  #   flash[:notice] =  I18n.t(:your_preferences_have_been_updated)  if params[:from_taxa_page].blank?
  #   store_location(EOLWebService.uri_remove_param(return_to_url, 'vetted')) if valid_return_to_url
  #   redirect_back_or_default
  #   #redirect_to(params[:return_to])
  # end


private

  def redirect_if_superceded
    redirect_to taxon_overview_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
  end

end
