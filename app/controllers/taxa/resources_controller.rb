class Taxa::ResourcesController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
  before_filter :add_page_view_log_entry, :update_user_content_level
  
  def show
    @assistive_section_header = I18n.t(:resources)
    @links = @taxon_concept.content_partners_links
    current_user.log_activity(:viewed_taxon_concept_resources_content_partners, :taxon_concept_id => @taxon_concept.id)
  end
  
  def identification_resources
    toc_id = TocItem.identification_resources.id
    @assistive_section_header = I18n.t(:resources)
    @contents = @taxon_concept.details_for_toc_items(ContentTable.details.toc_items, :language => current_user.language_abbr).collect{|d| d if d[:toc_item].id == toc_id}.compact
    current_user.log_activity(:viewed_taxon_concept_resources, :taxon_concept_id => @taxon_concept.id)
  end
  
  def education
    toc_id = TocItem.education.id
    @assistive_section_header = I18n.t(:resources)
    @contents = @taxon_concept.details_for_toc_items(ContentTable.details.toc_items, :language => current_user.language_abbr).collect{|d| d if d[:toc_item].parent_id == toc_id}.compact
    current_user.log_activity(:viewed_taxon_concept_resources_education, :taxon_concept_id => @taxon_concept.id)
  end
  
  def biomedical_terms
    if !Resource.ligercat.nil? && HierarchyEntry.find_by_hierarchy_id_and_taxon_concept_id(Resource.ligercat.hierarchy.id, @taxon_concept.id)
      @biomedical_exists = true
      toc_id = TocItem.biomedical_terms.id
      @assistive_section_header = I18n.t(:resources)
      @contents = @taxon_concept.details_for_toc_items(ContentTable.details.toc_items, :language => current_user.language_abbr).collect{|d| d if d[:toc_item].id == toc_id}.compact
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
  
private

  def redirect_if_superceded
    redirect_to taxon_details_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
  end
  
end