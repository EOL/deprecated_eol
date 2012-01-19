class Taxa::ResourcesController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    @assistive_section_header = I18n.t(:resources)
    @links = @taxon_concept.content_partners_links
    current_user.log_activity(:viewed_taxon_concept_resources_content_partners, :taxon_concept_id => @taxon_concept.id)
  end

  def identification_resources
    toc_id = TocItem.identification_resources.id
    @assistive_section_header = I18n.t(:resources)
    identification_resources_toc_items = ContentTable.details.toc_items.select{ |ti| ti.parent_id == toc_id || ti.id == toc_id}
    @contents = @taxon_concept.details_for_toc_items(identification_resources_toc_items, :language => current_user.language_abbr)
    current_user.log_activity(:viewed_taxon_concept_resources, :taxon_concept_id => @taxon_concept.id)
  end

  def education
    tocs = [TocItem.education, TocItem.education_resources].compact.map(&:id)
    @assistive_section_header = I18n.t(:resources)
    education_toc_items = ContentTable.details.toc_items.select do |ti|
      tocs.include?(ti.parent_id) || tocs.include?(ti.id)
    end
    @contents = @taxon_concept.details_for_toc_items(education_toc_items, :language => current_user.language_abbr)
    current_user.log_activity(:viewed_taxon_concept_resources_education, :taxon_concept_id => @taxon_concept.id)
  end

  def biomedical_terms
    if !Resource.ligercat.nil? && HierarchyEntry.find_by_hierarchy_id_and_taxon_concept_id(Resource.ligercat.hierarchy.id, @taxon_concept.id)
      @biomedical_exists = true
      toc_id = TocItem.biomedical_terms.id
      biomedical_terms_toc_items = ContentTable.details.toc_items.select{ |ti| ti.id == toc_id}
      @assistive_section_header = I18n.t(:resources)
      @contents = @taxon_concept.details_for_toc_items(biomedical_terms_toc_items, :language => current_user.language_abbr)
    else
      @biomedical_exists = false
    end
    current_user.log_activity(:viewed_taxon_concept_resources_biomedical_terms, :taxon_concept_id => @taxon_concept.id)
  end

  def nucleotide_sequences
    @assistive_section_header = I18n.t(:nucleotide_sequences)
    if @taxon_concept.nucleotide_sequences_hierarchy_entry_for_taxon.nil?
      @identifier = ''
    else
      @identifier = @taxon_concept.nucleotide_sequences_hierarchy_entry_for_taxon.identifier
    end
    current_user.log_activity(:viewed_taxon_concept_resources_nucleotide_sequences, :taxon_concept_id => @taxon_concept.id)
  end

protected
  def set_meta_description
    if @selected_hierarchy_entry
      @preferred_common_name ?
        I18n.t(:meta_description_hierarchy_entry_resources_with_common_name, :scientific_name => @scientific_name,
          :hierarchy_provider => @selected_hierarchy_entry.hierarchy_label,
          :preferred_common_name => @preferred_common_name) :
        I18n.t(:meta_description_hierarchy_entry_resources, :scientific_name => @scientific_name,
          :hierarchy_provider => @selected_hierarchy_entry.hierarchy_label)
    else
      @preferred_common_name ?
        I18n.t(:meta_description_taxon_resources_with_common_name, :scientific_name => @scientific_name,
          :preferred_common_name => @preferred_common_name) :
        I18n.t(:meta_description_taxon_resources, :scientific_name => @scientific_name)
    end
  end
  def additional_meta_keywords
   [ @preferred_common_name ?
      I18n.t(:meta_keywords_taxon_resources_with_common_name, :preferred_common_name => @preferred_common_name,
        :scientific_name => @scientific_name) :
      I18n.t(:meta_keywords_taxon_resources, :scientific_name => @scientific_name) ]
  end
end
