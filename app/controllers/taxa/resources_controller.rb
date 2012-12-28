class Taxa::ResourcesController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry, :link_objects_contents

  # TODO - Many of these are nearly identical. Why are we repeating ourselves so much, here? Generalize.

  def index
    @assistive_section_header = I18n.t(:resources)
    @links = @taxon_concept.content_partners_links
    @rel_canonical_href = taxon_resources_url(@taxon_page)
    current_user.log_activity(:viewed_taxon_concept_resources_content_partners, :taxon_concept_id => @taxon_concept.id)
  end

  def identification_resources
    @assistive_section_header = I18n.t(:resources)
    @add_link_type_id = nil
    @add_article_toc_id = TocItem.identification_resources ? TocItem.identification_resources.id : nil
    @rel_canonical_href = identification_resources_taxon_resources_url(@taxon_page)

    @contents = @taxon_page.text(
      :language_ids => [ current_language.id ],
      :toc_ids => [ TocItem.identification_resources.id ],
      :filter_by_subtype => true
    )
    current_user.log_activity(:viewed_taxon_concept_resources, :taxon_concept_id => @taxon_concept.id)
  end

  def citizen_science
    @assistive_section_header = I18n.t(:citizen_science)
    @add_link_type_id = nil
    @add_article_toc_id = TocItem.citizen_science_links ? TocItem.citizen_science_links.id : nil
    @rel_canonical_href = citizen_science_taxon_resources_url(@taxon_page)

    citizen_science = TocItem.cached_find_translated(:label, 'Citizen Science', 'en')
    citizen_science_links = TocItem.cached_find_translated(:label, 'Citizen Science links', 'en')
    @contents = @taxon_page.text(
      :language_ids => [ current_language.id ],
      :toc_ids => [ citizen_science.id, citizen_science_links.id ],
      :filter_by_subtype => true
    )
    current_user.log_activity(:viewed_taxon_concept_resources_citizen_science, :taxon_concept_id => @taxon_concept.id)
  end

  def education
    @assistive_section_header = I18n.t(:resources)
    @add_link_type_id = nil
    @add_article_toc_id = TocItem.education_resources ? TocItem.education_resources.id : nil
    @rel_canonical_href = education_taxon_resources_url(@taxon_page)
    
    # there are two education chapters - one is the parent of the other
    education_root = TocItem.cached_find_translated(:label, 'Education', 'en', :find_all => true).detect{ |toc_item| toc_item.is_parent? }
    education_chapters = [ education_root ] + education_root.children
    @contents = @taxon_page.text(
      :language_ids => [ current_language.id ],
      :toc_ids => education_chapters.collect{ |toc_item| toc_item.id },
      :filter_by_subtype => true
    )
    current_user.log_activity(:viewed_taxon_concept_resources_education, :taxon_concept_id => @taxon_concept.id)
  end

  def biomedical_terms
    if @taxon_concept.has_ligercat_entry?
      @assistive_section_header = I18n.t(:resources)
      @biomedical_exists = true
    else
      @biomedical_exists = false
    end
    @rel_canonical_href = biomedical_terms_taxon_resources_url(@taxon_page)
    current_user.log_activity(:viewed_taxon_concept_resources_biomedical_terms, :taxon_concept_id => @taxon_concept.id)
  end

  def nucleotide_sequences
    @assistive_section_header = I18n.t(:nucleotide_sequences)
    if @taxon_concept.nucleotide_sequences_hierarchy_entry_for_taxon.nil?
      @identifier = ''
    else
      @identifier = @taxon_concept.nucleotide_sequences_hierarchy_entry_for_taxon.identifier
    end
    @rel_canonical_href = nucleotide_sequences_taxon_resources_url(@taxon_page)
    current_user.log_activity(:viewed_taxon_concept_resources_nucleotide_sequences, :taxon_concept_id => @taxon_concept.id)
  end

  def news_and_event_links
    @assistive_section_header = I18n.t(:news_and_event_links)
    @add_article_toc_id = nil
    @add_link_type_id = LinkType.blog ? LinkType.blog.id : (LinkType.news ? LinkType.news.id : nil)
    @rel_canonical_href = news_and_event_links_taxon_resources_url(@taxon_page)
    current_user.log_activity(:viewed_taxon_concept_resources_news_and_event_links, :taxon_concept_id => @taxon_concept.id)
  end

  def related_organizations
    @assistive_section_header = I18n.t(:related_organizations)
    @add_article_toc_id = nil
    @add_link_type_id = LinkType.organization ? LinkType.organization.id : nil
    @rel_canonical_href = related_organizations_taxon_resources_url(@taxon_page)
    current_user.log_activity(:viewed_taxon_concept_resources_related_organizations, :taxon_concept_id => @taxon_concept.id)
  end

  def multimedia_links
    @assistive_section_header = I18n.t(:multimedia_links)
    @add_article_toc_id = nil
    @add_link_type_id = LinkType.multimedia ? LinkType.multimedia.id : nil
    @rel_canonical_href = multimedia_links_taxon_resources_url(@taxon_page)
    current_user.log_activity(:viewed_taxon_concept_resources_multimedia_links, :taxon_concept_id => @taxon_concept.id)
  end

private

  def link_objects_contents
    @news_and_event_links_contents ||= @taxon_page.text(
      :language_ids => [ current_language.id ],
      :link_type_ids => [ LinkType.news.id, LinkType.blog.id ]
    )
    @related_organizations_contents ||= @taxon_page.text(
      :language_ids => [ current_language.id ],
      :link_type_ids => [ LinkType.organization.id ]
    )
    @multimedia_links_contents ||= @taxon_page.text(
      :language_ids => [ current_language.id ],
      :link_type_ids => [ LinkType.multimedia.id ]
    )
  end

end
