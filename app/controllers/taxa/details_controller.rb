class Taxa::DetailsController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry, :literatures_and_resources_links

  # GET /pages/:taxon_id/details
  def index
    
    @text_objects = @taxon_concept.details_text_for_user(current_user)
    DataObject.preload_associations(@text_objects, { :toc_items => :parent })
    @toc_items_to_show = @taxon_concept.table_of_contents_for_text(@text_objects)
    
    @data_objects_in_other_languages = @taxon_concept.text_for_user(current_user, {
      :language_ids_to_ignore => [ current_language.id, 0 ],
      :allow_nil_languages => false,
      :preload_select => { :data_objects => [ :id, :guid, :language_id ] },
      :skip_preload => true,
      :toc_ids_to_ignore => TocItem.exclude_from_details.collect{ |toc_item| toc_item.id } })
    DataObject.preload_associations(@data_objects_in_other_languages, :language)
    @details_count_by_language = {}
    @data_objects_in_other_languages.each do |obj|
      @details_count_by_language[obj.language] ||= 0
      @details_count_by_language[obj.language] += 1
    end
    @summary_text = @taxon_concept.overview_text_for_user(current_user)
    @exemplar_image = @taxon_concept.exemplar_or_best_image_from_solr(@selected_hierarchy_entry)
    @assistive_section_header = I18n.t(:assistive_details_header)
    @rel_canonical_href = @selected_hierarchy_entry ?
      taxon_entry_details_url(@taxon_concept, @selected_hierarchy_entry) :
      taxon_details_url(@taxon_concept)
    current_user.log_activity(:viewed_taxon_concept_details, :taxon_concept_id => @taxon_concept.id)
  end

  def set_article_as_exemplar
    unless current_user && current_user.min_curator_level?(:assistant)
      raise EOL::Exceptions::SecurityViolation, "User does not have set_article_as_exemplar privileges"
      return
    end
    @taxon_concept = TaxonConcept.find(params[:taxon_id].to_i) rescue nil
    @data_object = DataObject.find_by_id(params[:data_object_id].to_i) rescue nil

    if @taxon_concept && @data_object
      TaxonConceptExemplarArticle.set_exemplar(@taxon_concept.id, @data_object.id)
      log_action(@taxon_concept, @data_object, :choose_exemplar_article)
    end

    store_location(params[:return_to] || request.referer)
    @taxon_concept.reload # This clears caches as well as any vars in memory.
    redirect_back_or_default taxon_details_path @taxon_concept.id
  end

protected
  def meta_description
    chapter_list = @toc_items_to_show.collect{|i| i.label}.uniq.compact.join("; ") unless @toc_items_to_show.blank?
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:chapter_list] = chapter_list unless chapter_list.blank?
    I18n.t("meta_description#{translation_vars[:preferred_common_name] ? '_with_common_name' :
           ''}#{translation_vars[:chapter_list] ? '_with_chapter_list' : '_no_data'}",
           translation_vars)
  end
  def meta_keywords
    keywords = super
    toc_subjects = @toc_items_to_show.collect{|i| i.label}.compact.join(", ")
    [keywords, toc_subjects].compact.join(', ')
  end
  
private
  def literatures_and_resources_links
    concept_link_type_ids = @taxon_concept.get_unique_link_type_ids_for_user(current_user, {
      :language_ids => [ current_language.id ] })
    concept_toc_ids = @taxon_concept.get_unique_toc_ids_for_user(current_user, {
      :language_ids => [ current_language.id ] })

    @show_resources_links = []
    @show_literature_references_links = []

    @show_resources_links << 'partner_links' unless @taxon_concept.content_partners_links.blank?
    @show_resources_links << 'identification_resources' if concept_toc_ids.include?(TocItem.identification_resources.id)

    citizen_science = TocItem.cached_find_translated(:label, 'Citizen Science', 'en')
    citizen_science_links = TocItem.cached_find_translated(:label, 'Citizen Science links', 'en')
    # & is array intersection
    @show_resources_links << 'citizen_science' unless (concept_toc_ids & [citizen_science.id, citizen_science_links.id]).empty?

    # there are two education chapters - one is the parent of the other
    education_root = TocItem.cached_find_translated(:label, 'Education', 'en', :find_all => true).detect{ |toc_item| toc_item.is_parent? }
    education_chapters = [ education_root ] + education_root.children
    education_toc_ids = education_chapters.collect{ |toc_item| toc_item.id }
    # & is array intersection
    @show_resources_links << 'education' unless (concept_toc_ids & education_toc_ids).empty?

    if !Resource.ligercat.nil? && HierarchyEntry.find_by_hierarchy_id_and_taxon_concept_id(Resource.ligercat.hierarchy.id, @taxon_concept.id)
      @show_resources_links << 'biomedical_terms'
    end
    @show_resources_links << 'nucleotide_sequences' unless @taxon_concept.nucleotide_sequences_hierarchy_entry_for_taxon.nil?
    @show_resources_links << 'news_and_event_links' unless (concept_link_type_ids & [LinkType.news.id, LinkType.blog.id]).empty?
    @show_resources_links << 'related_organizations' if concept_link_type_ids.include?(LinkType.organization.id)
    @show_resources_links << 'multimedia_links' if concept_link_type_ids.include?(LinkType.multimedia.id)

    @show_literature_references_links << 'literature_references' if Ref.literature_references_for?(@taxon_concept.id)
    @show_literature_references_links << 'literature_links' if concept_link_type_ids.include?(LinkType.paper.id)
  end
end
