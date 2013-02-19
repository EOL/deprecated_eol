# This represents the details (text objects) of a taxon concept, providing a minimal interface to only the aspects you
# might need to display one.
#
# NOTE that this class uses a plural name for a single instance; this is a fairly standard practice for these types of 
# Presenter objects, when appropriate.
class TaxonDetails < TaxonUserClassificationFilter

  def articles_in_other_languages?
    !count_by_language.blank?
  end

  def count_by_language
    return @count_by_language if defined? @count_by_language 
    @count_by_language = {}
    details_in_all_other_languages.select { |obj| obj.approved_language? }.each do |obj|
      @count_by_language[obj.language] ||= 0
      @count_by_language[obj.language] += 1
    end
    @count_by_language
  end

  def thumb?
    image && thumb
  end

  def thumb
    @thumb ||= image.thumb_or_object('260_190')
  end

  def toc_items?
    !toc_roots.empty?
  end

  # Passes back the child and the content for that child.
  def each_toc_item(&block)
    toc_roots.each do |toc_item|
      yield(toc_item, details_cache(toc_item))
    end
  end

  def toc_items_under?(under)
    !toc_nest_under(under).empty?
  end

  def each_nested_toc_item(under)
    toc_nest_under(under).each do |toc_item|
      yield(toc_item, details_cache(toc_item))
    end
  end

  # TODO - these two methods are extremely odd, and likely deserve their own class to handle.
  def resources_links
    return @resources_links if defined? @resources_links
    @resources_links = []
    # every page should have at least one partner (since we got the name from somewhere)
    @resources_links << :partner_links
    @resources_links << :identification_resources if toc_ids.include?(TocItem.identification_resources.id)
    # NOTE - & is array intersection
    @resources_links << :citizen_science unless (toc_ids & [TocItem.citizen_science.id, TocItem.citizen_science_links.id]).empty?
    @resources_links << :education unless (toc_ids & TocItem.education_toc_ids).empty?
    # TODO - I feel like we can move #has_ligercat_entry? ...but it's also used by TaxonResources.
    @resources_links << :biomedical_terms if taxon_concept.has_ligercat_entry?
    @resources_links << :nucleotide_sequences if taxon_concept.nucleotide_sequences_hierarchy_entry_for_taxon
    @resources_links << :news_and_event_links unless (link_type_ids & [LinkType.news.id, LinkType.blog.id]).empty?
    @resources_links << :related_organizations if link_type_ids.include?(LinkType.organization.id)
    @resources_links << :multimedia_links if link_type_ids.include?(LinkType.multimedia.id)
    @resources_links
  end

  def literature_references_links
    return @literature_references_links if defined? @literature_references_links
    @literature_references_links = []
    @literature_references_links << :literature_references if Ref.literature_references_for?(taxon_concept.id)
    @literature_references_links << :literature_links if link_type_ids.include?(LinkType.paper.id)
    @literature_references_links
  end

  def chapter_list
    if toc_items?
      @chapter_list ||= toc.map(&:label).uniq.compact
    else
      []
    end
  end

private

  def details_cache(item)
    @details_cache ||= {}
    @details_cache[item] ||= details(:include_toc_item => item)
  end

  def details(options = {})
    @details ||= details_text
    options[:include_toc_item] ? @details.select { |d| d.toc_items.include?(options[:include_toc_item]) } : @details
  end

  def details_text
    text_objects = taxon_concept.text_for_user(user,
      :language_ids => [ user.language_id ],
      :filter_by_subtype => true,
      :allow_nil_languages => user.default_language?,
      :toc_ids_to_ignore => TocItem.exclude_from_details.collect { |toc_item| toc_item.id },
      :per_page => 600 # NOTE - artificial limit of text objects here to increase the default 30
    )
    selects = {
      :hierarchy_entries => [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
      :hierarchies => [ :id, :agent_id, :browsable, :outlink_uri, :label ],
      :data_objects_hierarchy_entries => '*',
      :curated_data_objects_hierarchy_entries => '*',
      :data_object_translations => '*',
      :table_of_contents => '*',
      :info_items => '*',
      :toc_items => '*',
      :translated_table_of_contents => '*',
      :users_data_objects => '*',
      :resources => '*',
      :content_partners => 'id, user_id, full_name, display_name, homepage, public',
      :refs => '*',
      :ref_identifiers => '*',
      :comments => 'id, parent_id',
      :licenses => '*',
      :users_data_objects_ratings => '*' }
    DataObject.preload_associations(text_objects, [ :users_data_objects_ratings, :comments, :license,
      { :published_refs => :ref_identifiers }, :translations, :data_object_translation, { :toc_items => :info_items },
      { :data_objects_hierarchy_entries => [ { :hierarchy_entry => { :hierarchy => { :resource => :content_partner } } },
        :vetted, :visibility ] },
      { :curated_data_objects_hierarchy_entries => :hierarchy_entry }, :users_data_object,
      { :toc_items => [ :translations ] } ], :select => selects)
    DataObject.sort_by_rating(text_objects, taxon_concept)
  end

  def toc_nest_under(under)
    @toc_nest ||= {}
    @toc_nest[under] ||= toc(:under => under)
  end

  def toc_roots
    @toc_roots ||= toc.select { |item| ! item.is_child? }
  end

  def toc(options = {})
    @toc_items ||= TocItem.table_of_contents_for_text(details)
    options[:under] ?
      @toc_items.select { |toc_item| toc_item.parent_id == options[:under].id } :
      @toc_items
  end

  def details_in_all_other_languages
    return @details_in_all_other_languages if defined?(@details_in_all_other_languages)
    @details_in_all_other_languages = taxon_concept.text_for_user(user,
      :language_ids_to_ignore => user.language.all_ids << 0,
      :allow_nil_languages => false,
      :preload_select => { :data_objects => [ :id, :guid, :language_id, :data_type_id, :created_at, :rights_holder ] },
      :skip_preload => true,
      :toc_ids_to_ignore => TocItem.exclude_from_details.map { |toc_item| toc_item.id }
    )

    DataObject.preload_associations(@details_in_all_other_languages, :language)
    @details_in_all_other_languages ||= []
    @details_in_all_other_languages
  end

  def link_type_ids
    @link_type_ids ||= EOL::Solr::DataObjects.unique_link_type_ids(taxon_concept.id, default_solr_options)
  end

  def toc_ids
    @toc_ids ||= EOL::Solr::DataObjects.unique_toc_ids(taxon_concept.id, default_solr_options)
  end

  def default_solr_options
    TaxonConcept.default_solr_query_parameters(
      :data_type_ids => DataType.text_type_ids,
      :vetted_types => user.vetted_types,
      :visibility_types => user.visibility_types,
      :filter_by_subtype => false,
      :language_ids => [ user.language_id ]
    )
  end

end
