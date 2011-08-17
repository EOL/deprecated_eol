class Mobile::TaxaController < Mobile::MobileController
  
  include SharedTaxaController
  
  before_filter :instantiate_taxon_concept
  
  #before_filter :redirect_if_superceded, :redirect_if_invalid
  #before_filter :add_page_view_log_entry, :update_user_content_level
  
  def show
    includes = [
      { :published_hierarchy_entries => [ { :name => :ranked_canonical_form } , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => [ :toc_items,  :info_items, { :data_objects_hierarchy_entries => :hierarchy_entry },
        { :curated_data_objects_hierarchy_entries => :hierarchy_entry } ] },
      { :top_concept_images => { :data_object => [ :users_data_object,
        { :data_objects_hierarchy_entries => :hierarchy_entry },
        { :curated_data_objects_hierarchy_entries => :hierarchy_entry } ] } },
      { :curator_activity_logs => :user },
      { :users_data_objects => { :data_object => :toc_items } }]
    selects = {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :names => [ :string, :italicized, :canonical_form_id, :ranked_canonical_form_id ],
      :canonical_forms => [ :string ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :hierarchies_content => [ :content_level, :image, :text, :child_image, :map, :youtube, :flash ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :data_subtype_id, :published, :guid, :data_rating, :language_id ],
      :table_of_contents => '*',
      :data_objects_hierarchy_entries => '*',
      :curated_data_objects_hierarchy_entries => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name, :logo_cache_url, :tag_line ] }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)
    @browsable_hierarchy_entries ||= @taxon_concept.published_hierarchy_entries.select{ |he| he.hierarchy.browsable? }
    @browsable_hierarchy_entries = [@dropdown_hierarchy_entry] if @browsable_hierarchy_entries.blank? # TODO: Check this - we are getting here with a hierarchy entry that has a hierarchy that is not browsable.
    @browsable_hierarchy_entries.compact!
    @hierarchies = @browsable_hierarchy_entries.collect{|he| he.hierarchy }.uniq
    toc_items = [TocItem.brief_summary, TocItem.comprehensive_description, TocItem.distribution]
    options = {:limit => 1, :language => current_user.language_abbr}
    @summary_text = @taxon_concept.text_objects_for_toc_items(toc_items, options)

    if @selected_hierarchy_entry
      @recognized_by = recognized_by
    end

    @media = promote_exemplar(@taxon_concept.media({}, @selected_hierarchy_entry))
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @assistive_section_header = I18n.t(:assistive_overview_header)

    current_user.log_activity(:viewed_taxon_concept_overview, :taxon_concept_id => @taxon_concept.id)
  end
  
  def details
    includes = [
      { :published_hierarchy_entries => [ :name , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => [ :translations, :data_object_translation, { :toc_items => :info_items }, { :data_objects_hierarchy_entries => :hierarchy_entry },
        { :curated_data_objects_hierarchy_entries => :hierarchy_entry } ] },
      { :top_concept_images => { :data_object => [
        { :data_objects_hierarchy_entries => :hierarchy_entry },
        { :curated_data_objects_hierarchy_entries => :hierarchy_entry } ] } },
      { :curator_activity_logs => :user },
      { :users_data_objects => [ { :data_object => :toc_items } ] },
      { :taxon_concept_exemplar_image => :data_object }]
    selects = {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :names => [ :string, :italicized, :canonical_form_id, :ranked_canonical_form_id ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :hierarchies_content => [ :content_level, :image, :text, :child_image, :map, :youtube, :flash ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :data_subtype_id, :published, :guid, :data_rating, :object_cache_url, :language_id ],
      :data_objects_hierarchy_entries => '*',
      :curated_data_objects_hierarchy_entries => '*',
      :data_object_translations => '*',
      :table_of_contents => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name, :logo_cache_url ] ,
      :taxon_concept_exemplar_image => '*' }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)
    @taxon_concept.current_user = current_user
    @details = @taxon_concept.details_for_toc_items(ContentTable.details.toc_items, :language => current_user.language_abbr)

    toc_items_to_show = @details.blank? ? [] : @details.collect{|d| d[:toc_item]}
    
    # toc_items to exclude in Details tab
    temp = []
    # Education: 
    temp = temp | ["Education", "Education Links", "Education Resources", "High School Lab Series"]
    # Physical Description: 
    temp = temp | ["Morphology", "Size", "Diagnostic Description", "Look Alikes", "Development", "Identification Resources"]
    # Molecular Biology and Genetics: 
    temp = temp | ["Genetics", "Nucleotide Sequences", "Barcode", "Genome", "Molecular Biology"]
    # References and More Information: 
    temp = temp | ["Content Partners", "Literature References", "Bibliographies", "Bibliography", "Commentary", "On the Web", "Biodiversity Heritage Library", "Comments", "Search the Web", "Education Resources", "Biomedical Terms"]
    # Names and Taxonomy: 
    temp = temp | ["Related Names", "Synonyms", "Common Names"]
    # Page Statistics: 
    temp = temp | ["Content Summary"]
    # exclude selected toc_items
    toc_items_to_show.delete_if {|ti| temp.include?(ti.label)}

    @toc = TocBuilder.new.toc_for_toc_items(toc_items_to_show)

    @exemplar_image = @taxon_concept.taxon_concept_exemplar_image.data_object unless @taxon_concept.taxon_concept_exemplar_image.blank?
    @exemplar_image ||= @taxon_concept.best_image

    @watch_collection = logged_in? ? current_user.watch_collection : nil

    @assistive_section_header = I18n.t(:assistive_details_header)

    current_user.log_activity(:viewed_taxon_concept_details, :taxon_concept_id => @taxon_concept.id)
  end
  
  def media
    includes = [
      { :published_hierarchy_entries => [ :name , :hierarchy, :hierarchies_content, :vetted ] },
      { :data_objects => { :toc_items => :info_items } },
      { :top_concept_images => :data_object },
      { :curator_activity_logs => :user },
      { :users_data_objects => { :data_object => :toc_items } },
      { :taxon_concept_exemplar_image => :data_object }]
    selects = {
      :taxon_concepts => '*',
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :names => [ :string, :italicized, :canonical_form_id ],
      :hierarchies => [ :agent_id, :browsable, :outlink_uri, :label ],
      :hierarchies_content => [ :content_level, :image, :text, :child_image, :map, :youtube, :flash ],
      :vetted => :view_order,
      :data_objects => [ :id, :data_type_id, :data_subtype_id, :published, :guid, :data_rating, :object_cache_url, :source_url ],
      :table_of_contents => '*',
      :curator_activity_logs => '*',
      :users => [ :given_name, :family_name ],
      :taxon_concept_exemplar_image => '*' }
    @taxon_concept = TaxonConcept.core_relationships(:include => includes, :select => selects).find_by_id(@taxon_concept.id)
    @exemplar_image = @taxon_concept.taxon_concept_exemplar_image.data_object unless @taxon_concept.taxon_concept_exemplar_image.blank?

    @params_type = params['type'] || ['all']
    @params_status = params['status'] || []
    @sort_by = params[:sort_by]

    sort_order = [:visibility, :vetted, :rating, :date, :type] if @sort_by.blank? || @sort_by == 'status' #default
    sort_order = [:visibility, :rating, :vetted, :date, :type] if @sort_by == 'rating'
    sort_order = [:visibility, :date, :vetted, :rating, :type] if @sort_by == 'newest'

    @media = @taxon_concept.media(sort_order)
    @media = DataObject.custom_filter(@media, @taxon_concept, @params_type, @params_status) unless @params_type.blank? && @params_status.blank?

    @media = promote_exemplar(@media) if @exemplar_image && (@sort_by.blank? ||
      (@sort_by == 'status' && (@params_type.include?('all') || @params_type.include?('images'))))

    @sort_by ||= 'status'

    @media = @media.paginate(:page => params[:page] || 1, :per_page => $MAX_IMAGES_PER_PAGE)

    @watch_collection = logged_in? ? current_user.watch_collection : nil

    @assistive_section_header = I18n.t(:assistive_media_header)

    current_user.log_activity(:viewed_taxon_concept_media, :taxon_concept_id => @taxon_concept.id)
  end
  
end

