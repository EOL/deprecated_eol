# The information needed to build a taxon page: specifically, to filter all of the data appropriate to a user and an
# optional hierarchy.
#
# Put another way, this is an interface to the TaxonConcept that is aware of the 
class TaxonPage

  attr_reader :taxon_concept, :user, :hierarchy_entry

  def initialize(taxon_concept, user, hierarchy_entry = nil) 
    @taxon_concept = taxon_concept
    @user = user # TODO - we'll make more use of this later. For now, TaxonConcept uses it directly:
    # NOTE - this next command loads the taxon concept (if it hasn't been already), so we may want to do some
    # preloading magic, here:
    @taxon_concept.current_user = @user
    @hierarchy_entry = hierarchy_entry
  end

  # Use this one when you DON'T care if the page is filtered or not:
  def entry
    hierarchy_entry || @taxon_concept.entry
  end

  def hierarchy
    hierarchy_entry ? hierarchy_entry.hierarchy : taxon_concept.hierarchy
  end

  # We want to delegate damn near eveything to TaxonConcept... but don't want to maintain a list of those methods:
  # But note that we do NOT delegate the methods defined in this class (obviously), so pay attention to them!
  def method_missing(method, *args, &block)
    super unless taxon_concept.respond_to?(method)
    class_eval { delegate method, :to => :taxon_concept } # Won't use method_missing next time!
    taxon_concept.send(method, *args, &block)
  end

  def hierarchy_entries
    return @hierarchy_entries if @hierarchy_entries
    # TODO - change the #select to a #where so it's not loaded until needed:
    # ...though... don't we have a published_browsable_hierarchy_entries?
    # TODO - Eager load hierarchy entry agents?
    @hierarchy_entries = @taxon_concept.published_hierarchy_entries.includes(:hierarchy).select { |he|
      he.hierarchy.browsable? }.compact
    @hierarchy_entries = [hierarchy_entry] if hierarchy_entry && @hierarchy_entries.empty?
    @hierarchy_entries
  end

  # This is perhaps a bit too confusing: this checks if the *filtered* page really has a map (as opposed to whether
  # there is any map at all without filters):
  def map?
    map_taxon_concept.has_map && map # TODO - question mark
  end

  # TODO - this belongs on TaxonOverview
  def map
    return @map if @map
    map_results = taxon_concept.data_objects_from_solr(
      :page => 1, 
      :per_page => 1,
      :data_type_ids => DataType.image_type_ids,
      :data_subtype_ids => DataType.map_type_ids,
      :vetted_types => ['trusted', 'unreviewed'],
      :visibility_types => ['visible'],
      :ignore_translations => true,
      :skip_preload => true
    )
    @map = map_results.blank? ? nil : map_results.first
  end

  def gbif_map_id
    map_taxon_concept.gbif_map_id
  end

  def map_taxon_concept
    @map_taxon_concept ||= hierarchy_entry ? hierarchy_entry.taxon_concept : taxon_concept
  end

  # TODO - this belongs on TaxonOverview... but review.
  def top_media
    @images ||= promote_exemplar_image(
      taxon_concept.images_from_solr(
        map? ? 3 : 4, { :filter_hierarchy_entry => hierarchy_entry, :ignore_translations => true }
      )
    ).compact
    @images = map? ? (@images[0..2] << map) : @images
    @images
  end

  # This is used by the TaxaController (and thus all its children) to help build information for ALL translations:
  def hierarchy_provider
    hierarchy_entry ? hierarchy_entry.hierarchy_label.presence : nil
  end

  def scientific_name
    # TODO - Why? hierarchy_entry has a title_canonical_italicized method which actually seems "smarter"... soooo...
    hierarchy_entry ? hierarchy_entry.italicized_name : taxon_concept.title_canonical_italicized
  end

  # TODO - don't we count these somewhere?  Seems like a bit of a waste to get the count and not save it.
  def synonyms?
    hierarchy_entry ? hierarchy_entry.scientific_synonyms.length > 0 :
      taxon_concept.count_of_viewable_synonyms > 0
  end

  def can_be_reindexed?
    return false if hierarchy_entry
    return false unless user.min_curator_level?(:master)
    !taxon_concept.classifications_locked?
  end

  def can_set_exemplars?
    return false if hierarchy_entry
    return false unless user.min_curator_level?(:assistant)
    true
  end

  # TODO - git grep hierarchy_entry.rank_label  ... replace all of those with this:
  def classified_by
    entry.rank_label
  end

  # TODO - Clean this up...
  def related_names
    filter = hierarchy_entry ? "id=#{hierarchy_entry.id}" : "taxon_concept_id=#{taxon_concept.id}"

    parents = TaxonConcept.connection.execute("
      SELECT n.id name_id, n.string name_string, n.canonical_form_id, he_parent.taxon_concept_id, h.label hierarchy_label, he_parent.id hierarchy_entry_id
      FROM hierarchy_entries he_parent
      JOIN hierarchy_entries he_child ON (he_parent.id=he_child.parent_id)
      JOIN names n ON (he_parent.name_id=n.id)
      JOIN hierarchies h ON (he_child.hierarchy_id=h.id)
      WHERE he_child.#{filter}
      AND he_parent.published = 1
      AND browsable = 1
    ")

    children = TaxonConcept.connection.execute("
      SELECT n.id name_id, n.string name_string, n.canonical_form_id, he_child.taxon_concept_id, h.label hierarchy_label, he_child.id hierarchy_entry_id
      FROM hierarchy_entries he_parent
      JOIN hierarchy_entries he_child ON (he_parent.id=he_child.parent_id)
      JOIN names n ON (he_child.name_id=n.id)
      JOIN hierarchies h ON (he_parent.hierarchy_id=h.id)
      WHERE he_parent.#{filter}
      AND he_child.published = 1
      AND browsable = 1
    ")

    {'parents' => group_he_results(parents), 'children' => group_he_results(children)}
  end

  def related_names_count
    if related_names.blank?
      return 0
    else
      related_names_count = related_names['parents'].count
      related_names_count += related_names['children'].count
    end
  end

  def details?
    taxon_concept.has_details_text_for_user?(user)
  end

  # TODO - This belongs on TaxonNames or the like:
  # TODO - rewrite EOL::CommonNameDisplay to make use of TaxonPage... and to not suck.
  # options are just passed along to EOL::CommonNameDisplay.
  def common_names(options)
    return @common_names if @common_names
    if hierarchy_entry
      names = EOL::CommonNameDisplay.find_by_hierarchy_entry_id(hierarchy_entry.id, options)
    else
      names = EOL::CommonNameDisplay.find_by_taxon_concept_id(taxon_concept.id, nil, options)
    end
    @common_names = names.select {|name| !name.language.iso_639_1.blank? || !name.language.iso_639_2.blank? }
    @common_names
  end

  # TODO - this belongs on TaxonNames... sort of. Really, this should be re-thought; I don't think we want *hierarchy
  # entries* in the views, we probably want something else.
  # TODO - this is only barely different from #hierarchy_entries ... why?
  def hierarchy_entries_for_names
    return @hierarchy_entries_for_names if @hierarchy_entries_for_names
    @hierarchy_entries_for_names = taxon_concept.published_browsable_hierarchy_entries
    @hierarchy_entries_for_names = [hierarchy_entry] if hierarchy_entry # TODO - check this... really?
    HierarchyEntry.preload_associations(
      @hierarchy_entries_for_names,
      [ { :agents_hierarchy_entries => :agent }, :rank, { :hierarchy => :agent } ],
      :select => {:hierarchy_entries => [:id, :parent_id, :taxon_concept_id]}
    )
    @hierarchy_entries_for_names
  end

  # TODO - This belongs in TaxonMedia or the like:
  # Recall, hierarchy_entry can be nil
  def facets
    @facets ||= EOL::Solr::DataObjects.get_aggregated_media_facet_counts(
      taxon_concept.id, :filter_hierarchy_entry => hierarchy_entry, :user => user
    )
  end

  # TODO - This belongs in TaxonMedia
  def media(options = {})
    @media ||= @taxon_concept.data_objects_from_solr(options.merge(
      :ignore_translations => true,
      :filter_hierarchy_entry => entry,
      :return_hierarchically_aggregated_objects => true,
      :skip_preload => true,
      :preload_select => { :data_objects => [ :id, :guid, :language_id, :data_type_id, :created_at ] }
    ))
  end

  # Overriding this because it doesn't need to take the user anymore:
  def media_count
    @media_count ||= taxon_concept.media_count(user, hierarchy_entry)
  end

  # TODO - This belongs on TaxonConceptOverview
  def text
    taxon_concept.overview_text_for_user(user)
  end

  # TODO - this prolly belongs on TaxonConceptOverview, not here, but I'm not sure...
  def image
    taxon_concept.exemplar_or_best_image_from_solr(entry)
  end

  # helper.link_to "foo", app.overview_taxon_path(taxon_page) # Results depend on hierarchy entry:
  # => "<a href=\"/pages/910093/hierarchy_entries/16/overview\">foo</a>"
  # OR
  # => "<a href=\"/pages/910093/overview\">foo</a>"
  def to_param
    hierarchy_entry ? "#{taxon_concept.to_param}/hierarchy_entries/#{hierarchy_entry.to_param}" :
                      "#{taxon_concept.to_param}"
  end

  def classifcation_filter?
    hierarchy_entry
  end

private

  def promote_exemplar_image(data_objects)
    # TODO: a comment may be needed. If the concept is blank, why would there be images to promote?
    # we should just return
    if taxon_concept.blank? || taxon_concept.published_exemplar_image.blank?
      exemplar_image = data_objects[0] unless data_objects.blank?
    else
      exemplar_image = taxon_concept.published_exemplar_image
    end
    unless exemplar_image.nil?
      data_objects.delete_if{ |d| d.guid == exemplar_image.guid }
      data_objects.unshift(exemplar_image)
    end
    data_objects
  end

  # TODO - clean up
  def group_he_results(results)
    grouped = {}
    name_string_i = results.fields.index('name_string')
    hierarchy_label_i = results.fields.index('hierarchy_label')
    taxon_concept_id_i = results.fields.index('taxon_concept_id')
    hierarchy_entry_id_i = results.fields.index('hierarchy_entry_id')
    results.each do |result|
      key = "#{result[name_string_i].downcase}|#{result[taxon_concept_id_i]}"
      grouped[key] ||= {
        'taxon_concept_id' => result[taxon_concept_id_i],
        'name_string' => result[name_string_i],
        'sources' => [],
        'hierarchy_entry_id' => result[hierarchy_entry_id_i]
      }
      grouped[key]['sources'] << result[hierarchy_label_i]
    end
    grouped.each do |key, hash|
      hash['sources'].sort! {|a,b| a[hierarchy_label_i] <=> b[hierarchy_label_i]}
    end
    grouped = grouped.sort {|a,b| a[0] <=> b[0]}
  end

end
