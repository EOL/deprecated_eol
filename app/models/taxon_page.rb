# This is an interface to the TaxonConcept that is aware of the user and whether the user wants to see data from a
# single partner or not. This would be a good class to use to build a webpage. :)
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
  # TODO - this should really be renamed to hierarchy_entry, and the current #hierarchy_entry should be a *private*
  # method to store the HE... perhaps just _hierarchy_entry (with the leading underscore)... but we need to make sure
  # we're calling #classifcation_filter? where appropriate instead of checking #hierarchy_entry...
  def entry
    hierarchy_entry || @taxon_concept.entry
  end

  def classifcation_filter?
    hierarchy_entry
  end

  def hierarchy
    classifcation_filter? ? hierarchy_entry.hierarchy : taxon_concept.hierarchy
  end

  # We want to delegate damn near eveything to TaxonConcept... but don't want to maintain a list of those methods:
  # But note that we do NOT delegate the methods defined in this class (obviously), so pay attention to them!
  # NOTE - someday we might want to stop doing this, so that TaxonPage (or the other classes that rely on it) has a
  # nice, mangageable interface to all of the information we might want about a TaxonConcept.
  def method_missing(method, *args, &block)
    super unless taxon_concept.respond_to?(method)
    class_eval { delegate method, :to => :taxon_concept } # Won't use method_missing next time!
    taxon_concept.send(method, *args, &block)
  end

  def hierarchy_entries
    return @hierarchy_entries if @hierarchy_entries
    @hierarchy_entries = taxon_concept.published_browsable_hierarchy_entries
    @hierarchy_entries = [hierarchy_entry] if hierarchy_entry && @hierarchy_entries.empty?
    HierarchyEntry.preload_associations(
      @hierarchy_entries,
      [ { :agents_hierarchy_entries => :agent }, :rank, { :hierarchy => :agent } ],
      :select => {:hierarchy_entries => [:id, :parent_id, :taxon_concept_id]}
    )
    @hierarchy_entries
  end

  def gbif_map_id
    map_taxon_concept.gbif_map_id
  end

  # This is perhaps a bit too confusing: this checks if the *filtered* page really has a map (as opposed to whether
  # there is any map at all without filters):
  def map?
    map_taxon_concept.has_map? && map
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
    classifcation_filter? ? hierarchy_entry.hierarchy_provider : nil
  end

  def scientific_name
    hierarchy_entry_or_taxon_concept.title_canonical_italicized
  end

  # NOTE - Seems like a bit of a waste to get the count and not save it, but I don't think we use the counts.
  def synonyms?
    classifcation_filter? ? hierarchy_entry.scientific_synonyms.length > 0 :
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

  def classified_by
    hierarchy_entry_or_taxon_concept.classified_by
  end

  def related_names
    @related_names ||=
      {'parents' => build_related_names_hash(get_related_names(:parents)),
       'children' => build_related_names_hash(get_related_names(:children))}
  end

  def related_names_count
    related_names['parents'].count + related_names['children'].count
  end

  def details?
    details_text_for_user(:only_one)
  end

  def details
    @details ||= details_text_for_user
  end
  
  # TODO - This belongs on TaxonNames or the like:
  # TODO - rewrite EOL::CommonNameDisplay to make use of TaxonPage... and to not suck.
  # options are just passed along to EOL::CommonNameDisplay.
  def common_names(options = {})
    return @common_names if @common_names
    if hierarchy_entry
      names = EOL::CommonNameDisplay.find_by_hierarchy_entry_id(hierarchy_entry.id, options)
    else
      names = EOL::CommonNameDisplay.find_by_taxon_concept_id(taxon_concept.id, nil, options)
    end
    @common_names = names.select {|name| name.known_language? }
    @common_names
  end

  # TODO - This belongs in TaxonMedia or the like:
  # NOTE - hierarchy_entry can be nil
  def facets
    @facets ||= EOL::Solr::DataObjects.get_aggregated_media_facet_counts(
      taxon_concept.id, :filter_hierarchy_entry => hierarchy_entry, :user => user
    )
  end

  # TODO - This belongs in TaxonMedia
  def media(options = {})
    @media ||= taxon_concept.data_objects_from_solr(options.merge(
      :ignore_translations => true,
      :filter_hierarchy_entry => entry,
      :return_hierarchically_aggregated_objects => true,
      :skip_preload => true,
      :preload_select => { :data_objects => [ :id, :guid, :language_id, :data_type_id, :created_at ] }
    ))
  end

  def media_count
    @media_count ||= taxon_concept.media_count(user, hierarchy_entry)
  end

  # TODO - This belongs on TaxonConceptOverview
  def summary_text
    taxon_concept.overview_text_for_user(user)
  end

  def text(options = {})
    taxon_concept.text_for_user(user, options)
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
    classifcation_filter? ? "#{taxon_concept.to_param}/hierarchy_entries/#{hierarchy_entry.to_param}" :
                            taxon_concept.to_param
  end

private

  def hierarchy_entry_or_taxon_concept
    hierarchy_entry || taxon_concept
  end

  def map_taxon_concept
    @map_taxon_concept ||= classifcation_filter? ? hierarchy_entry.taxon_concept : taxon_concept
  end

  # NOTE - the field aliases used in this query are required by #build_related_names_hash and are used in views.
  def get_related_names(which)
    from = which == :children ? 'he_child' : 'he_parent'
    other = which == :children ? 'he_parent' : 'he_child'
    filter = classifcation_filter? ? "id=#{hierarchy_entry.id}" : "taxon_concept_id=#{taxon_concept.id}"
    # NOTE - if you chande this at all... even a space... the spec will fail. Perhaps you should re-write this? For
    # example, could you make this a method on HierarchyEntry and create scopes using that method in a lambda?
    HierarchyEntry.connection.execute("
      SELECT n.id name_id, n.string name_string, n.canonical_form_id, #{from}.taxon_concept_id,
        h.label hierarchy_label, #{from}.id hierarchy_entry_id
      FROM hierarchy_entries he_parent
      JOIN hierarchy_entries he_child ON (he_parent.id=he_child.parent_id)
      JOIN names n ON (#{from}.name_id=n.id)
      JOIN hierarchies h ON (#{other}.hierarchy_id=h.id)
      WHERE #{other}.#{filter}
      AND #{from}.published = 1
      AND browsable = 1
    ")
  end

  # NOTE - if the exemplar was not in data_objects, we'll end up with a longer list. ...Is this dangerous?
  def promote_exemplar_image(data_objects)
    return data_objects unless taxon_concept.published_exemplar_image
    data_objects.delete_if { |d| d.guid == taxon_concept.published_exemplar_image.guid }
    data_objects.unshift(taxon_concept.published_exemplar_image)
    data_objects
  end

  # TODO - These are hashes that are used in the view(s), but we should document (or make obvious) how they are
  # constructed and used:
  # This is a method used to build and sort the hash we use in related names (synonyms) views (and sort the sources).
  def build_related_names_hash(results)
    # NOTE - these field names come from the #get_related_names query.
    name_string_i = results.fields.index('name_string')
    hierarchy_label_i = results.fields.index('hierarchy_label')
    taxon_concept_id_i = results.fields.index('taxon_concept_id')
    hierarchy_entry_id_i = results.fields.index('hierarchy_entry_id')
    grouped = {}
    results.each do |result|
      key = "#{result[name_string_i].downcase}|#{result[taxon_concept_id_i]}"
      grouped[key] ||= {
        'taxon_concept_id' => result[taxon_concept_id_i],
        'name_string' => result[name_string_i],
        'sources' => [], # NOTE - there can be many values of this for one key, so...
        'hierarchy_entry_id' => result[hierarchy_entry_id_i]
      }
      grouped[key]['sources'] << result[hierarchy_label_i] # ...we do this separately.
    end
    grouped.values.each do |hash|
      hash['sources'].sort! {|a,b| a[hierarchy_label_i] <=> b[hierarchy_label_i]}
    end
    grouped.sort {|a,b| a[0] <=> b[0]}
  end

  # TODO - there are three other methods related to this one, but I don't want to move them yet.
  # there is an artificial limit of 600 text objects here to increase the default 30
  def details_text_for_user(only_one = false)
    text_objects = taxon_concept.text_for_user(user,
      :language_ids => [ user.language_id ],
      :filter_by_subtype => true,
      :allow_nil_languages => user.default_language?,
      :toc_ids_to_ignore => TocItem.exclude_from_details.collect { |toc_item| toc_item.id },
      :per_page => (only_one ? 1 : 600)
    )
    
    # now preload info needed for display details metadata
    unless only_one
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
        :resources => 'id, content_partner_id, title, hierarchy_id',
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
    end
    text_objects
  end
  
end
