class Taxa::ResourcesController < TaxaController
  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :link_objects_contents
  before_filter :show_add_link_buttons

  def index
    @assistive_section_header = I18n.t(:resources)
    @rel_canonical_href = taxon_resources_url(@taxon_page)
  end

  def partner_links
    @assistive_section_header = I18n.t(:resources)
    @links = @taxon_concept.content_partners_links
    @rel_canonical_href = partner_links_taxon_resources_url(@taxon_page)
  end

  def identification_resources
    @assistive_section_header = I18n.t(:resources)
    @add_article_toc_id = TocItem.identification_resources ? TocItem.identification_resources.id : nil
    @rel_canonical_href = identification_resources_taxon_resources_url(@taxon_page)

    @contents = @identification_contents || get_toc_text(:identification_resources)
  end

  def citizen_science
    @assistive_section_header = I18n.t(:taxon_citizen_science_header)
    @add_article_toc_id = TocItem.citizen_science_links ? TocItem.citizen_science_links.id : nil
    @rel_canonical_href = citizen_science_taxon_resources_url(@taxon_page)

    @contents = @citizen_science_contents || get_toc_text([:citizen_science, :citizen_science_links])
  end

  def education
    @assistive_section_header = I18n.t(:resources)
    @add_article_toc_id = TocItem.education_resources ? TocItem.education_resources.id : nil
    @rel_canonical_href = education_taxon_resources_url(@taxon_page)

    @contents = @education_contents || get_toc_text(:education_for_resources_tab)
  end

  def biomedical_terms
    if @taxon_concept.has_ligercat_entry?
      @assistive_section_header = I18n.t(:resources)
      @biomedical_exists = true
    else
      @biomedical_exists = false
    end
    @rel_canonical_href = biomedical_terms_taxon_resources_url(@taxon_page)
  end

  def nucleotide_sequences
    @assistive_section_header = I18n.t(:nucleotide_sequences)
    if @taxon_concept.nucleotide_sequences_hierarchy_entry_for_taxon.nil?
      @identifier = ''
    else
      @identifier = @taxon_concept.nucleotide_sequences_hierarchy_entry_for_taxon.identifier
    end
    @rel_canonical_href = nucleotide_sequences_taxon_resources_url(@taxon_page)
  end

  def news_and_event_links
    @assistive_section_header = I18n.t(:news_and_event_links)
    @add_article_toc_id = nil
    @add_link_type_id = LinkType.blog ? LinkType.blog.id : (LinkType.news ? LinkType.news.id : nil)
    @show_add_link_buttons = @add_link_type_id
    @rel_canonical_href = news_and_event_links_taxon_resources_url(@taxon_page)
  end

  def related_organizations
    @assistive_section_header = I18n.t(:related_organizations)
    @add_article_toc_id = nil
    @add_link_type_id = LinkType.organization ? LinkType.organization.id : nil
    @show_add_link_buttons = @add_link_type_id
    @rel_canonical_href = related_organizations_taxon_resources_url(@taxon_page)
  end

  def multimedia_links
    @assistive_section_header = I18n.t(:multimedia_links)
    @add_article_toc_id = nil
    @add_link_type_id = LinkType.multimedia ? LinkType.multimedia.id : nil
    @show_add_link_buttons = @add_link_type_id
    @rel_canonical_href = multimedia_links_taxon_resources_url(@taxon_page)
  end

private

  def link_objects_contents
    @news_and_event_links_contents ||= get_link_text([:news, :blog])
    @related_organizations_contents ||= get_link_text(:organization)
    @multimedia_links_contents ||= get_link_text([:multimedia, :paper])
    @citizen_science_contents = get_toc_text([:citizen_science, :citizen_science_links])
    @identification_contents = get_toc_text(:identification_resources)
    @education_contents = get_toc_text(:education_for_resources_tab)
  end

  def get_link_text(which)
    types = Array(which).map { |t| LinkType.send(t).id }
    @taxon_page.text(
      language_ids: [ current_language.id ],
      link_type_ids: types
    )
  end

  def get_toc_text(which)
    # A little messier, since it can get arrays back:
    types = Array(which).flat_map { |t| TocItem.send(t) }.map(&:id)
    @taxon_page.text(
      language_ids: [ current_language.id ],
      toc_ids: types,
      filter_by_subtype: true
    )
  end

  def show_add_link_buttons
    @show_add_link_buttons = true
  end

end
