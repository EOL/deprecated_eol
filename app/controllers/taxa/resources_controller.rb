class Taxa::ResourcesController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @assistive_section_header = I18n.t(:resources)
    @links = @taxon_concept.content_partners_links
    @rel_canonical_href = @selected_hierarchy_entry ?
      taxon_entry_resources_url(@taxon_concept, @selected_hierarchy_entry) :
      taxon_resources_url(@taxon_concept)
    current_user.log_activity(:viewed_taxon_concept_resources_content_partners, :taxon_concept_id => @taxon_concept.id)
  end

  def identification_resources
    @assistive_section_header = I18n.t(:resources)
    @add_article_toc_id = TocItem.identification_resources ? TocItem.identification_resources.id : nil
    @rel_canonical_href = @selected_hierarchy_entry ?
      identification_resources_taxon_entry_resources_url(@taxon_concept, @selected_hierarchy_entry) :
      identification_resources_taxon_resources_url(@taxon_concept)

    @contents = @taxon_concept.text_for_user(current_user, {
      :language_ids => [ current_language.id ],
      :toc_ids => [ TocItem.identification_resources.id ] })
    current_user.log_activity(:viewed_taxon_concept_resources, :taxon_concept_id => @taxon_concept.id)
  end

  def citizen_science
    @assistive_section_header = I18n.t(:citizen_science)
    @add_article_toc_id = TocItem.citizen_science_links ? TocItem.citizen_science_links.id : nil
    @rel_canonical_href = @selected_hierarchy_entry ?
      citizen_science_taxon_entry_resources_url(@taxon_concept, @selected_hierarchy_entry) :
      citizen_science_taxon_resources_url(@taxon_concept)

    citizen_science = TocItem.cached_find_translated(:label, 'Citizen Science', 'en')
    citizen_science_links = TocItem.cached_find_translated(:label, 'Citizen Science links', 'en')
    @contents = @taxon_concept.text_for_user(current_user, {
      :language_ids => [ current_language.id ],
      :toc_ids => [ citizen_science.id, citizen_science_links.id ] })
    current_user.log_activity(:viewed_taxon_concept_resources_citizen_science, :taxon_concept_id => @taxon_concept.id)
  end

  def education
    @assistive_section_header = I18n.t(:resources)
    @add_article_toc_id = TocItem.education_resources ? TocItem.education_resources.id : nil
    @rel_canonical_href = @selected_hierarchy_entry ?
      education_taxon_entry_resources_url(@taxon_concept, @selected_hierarchy_entry) :
      education_taxon_resources_url(@taxon_concept)
    
    # there are two education chapters - one is the parent of the other
    education_root = TocItem.cached_find_translated(:label, 'Education', 'en', :find_all => true).detect{ |toc_item| toc_item.is_parent? }
    education_chapters = [ education_root ] + education_root.children
    @contents = @taxon_concept.text_for_user(current_user, {
      :language_ids => [ current_language.id ],
      :toc_ids => education_chapters.collect{ |toc_item| toc_item.id } })
    current_user.log_activity(:viewed_taxon_concept_resources_education, :taxon_concept_id => @taxon_concept.id)
  end

  def biomedical_terms
    if !Resource.ligercat.nil? && HierarchyEntry.find_by_hierarchy_id_and_taxon_concept_id(Resource.ligercat.hierarchy.id, @taxon_concept.id)
      @assistive_section_header = I18n.t(:resources)
      @biomedical_exists = true
    else
      @biomedical_exists = false
    end
    @rel_canonical_href = @selected_hierarchy_entry ?
      biomedical_terms_taxon_entry_resources_url(@taxon_concept, @selected_hierarchy_entry) :
      biomedical_terms_taxon_resources_url(@taxon_concept)
    current_user.log_activity(:viewed_taxon_concept_resources_biomedical_terms, :taxon_concept_id => @taxon_concept.id)
  end

  def nucleotide_sequences
    @assistive_section_header = I18n.t(:nucleotide_sequences)
    if @taxon_concept.nucleotide_sequences_hierarchy_entry_for_taxon.nil?
      @identifier = ''
    else
      @identifier = @taxon_concept.nucleotide_sequences_hierarchy_entry_for_taxon.identifier
    end
    @rel_canonical_href = @selected_hierarchy_entry ?
      nucleotide_sequences_taxon_entry_resources_url(@taxon_concept, @selected_hierarchy_entry) :
      nucleotide_sequences_taxon_resources_url(@taxon_concept)
    current_user.log_activity(:viewed_taxon_concept_resources_nucleotide_sequences, :taxon_concept_id => @taxon_concept.id)
  end

end
