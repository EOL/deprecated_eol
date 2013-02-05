# This is an interface to the TaxonConcept that is aware of the user and whether the user wants to see data from a
# single partner or not. This would be a good class to use to build a webpage. :)
#
# NOTE - when you create a TaxonPage, the TaxonConcept is *immediately* loaded, if it wasn't already... so if you're
# counting on ARel to handle lazy loading, you will want to attach any selects and includes *before* calling
# TaxonPage.
class TaxonPage

  attr_reader :taxon_concept, :user

  # The hierarchy_entry is optional and, if provided, creates a classification filter using that entry. We use
  # entries instead of classifications for mainly historical reasons... we *could* use a hierarchy instead, though
  # it's ultimately the hierarchy_entry that we need anyway.
  def initialize(taxon_concept, user, hierarchy_entry = nil) 
    @taxon_concept = taxon_concept
    @user = user
    @taxon_concept.current_user = user
    @_hierarchy_entry = hierarchy_entry
  end

  # NOTE - *THIS IS IMPORTANT* ... when you see "_hierarchy_entry", it means "the one specified by initialize." When
  # you see "hierarchy_entry" (no leading underscore) it means "do the right thing".
  def hierarchy_entry
    _hierarchy_entry || @taxon_concept.entry
  end

  def classifcation_filter?
    _hierarchy_entry
  end

  def classification_entry
    return _hierarchy_entry if classifcation_filter?
    return @classification_entry if @classification_entry
    if chosen = taxon_concept.curator_chosen_classification
      @classification_chosen_by = chosen.user
      @classification_entry = chosen.hierarchy_entry
    else
      @classification_entry = hierarchy_entries.shuffle.first
      @classification_entry ||= deep_published_nonbrowsable_hierarchy_entries.shuffle.first
      @classification_entry ||= hierarchy_entry
    end
    @classification_entry
  end

  def classification
    classification_entry.hierarchy
  end

  def classification_chosen_by
    return @classification_chosen_by if @classification_chosen_by
    chosen = taxon_concept.curator_chosen_classification
    @classification_chosen_by = chosen ? chosen.user : nil
  end

  def classification_curated?
    @classification_curated ||= taxon_concept.curator_chosen_classification
  end

  def hierarchy
    classifcation_filter? ? _hierarchy_entry.hierarchy : taxon_concept.hierarchy
  end

  def kingdom
    classifcation_filter? ? _hierarchy_entry.kingdom : hierarchy_entry.kingdom
  end

  # We're not inheriting from Delegator here, because we want to be more surgical about what gets called on
  # TaxonConcept... but this sets up *almost* everything to go to the TC (without maintaining a full list).
  # TODO - we might want to stop doing this, so that TaxonPage (or the other classes that rely on it) has a
  # nice, mangageable interface to all of the information we might want about a TaxonConcept.
  def method_missing(method, *args, &block)
    super unless taxon_concept.respond_to?(method)
    class_eval { delegate method, :to => :taxon_concept } # Won't use method_missing next time!
    taxon_concept.send(method, *args, &block)
  end

  def hierarchy_entries
    return @hierarchy_entries if @hierarchy_entries
    @hierarchy_entries = taxon_concept.published_browsable_hierarchy_entries
    @hierarchy_entries = [_hierarchy_entry] if _hierarchy_entry && @hierarchy_entries.empty?
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
        map? ? 3 : 4, { :filter_hierarchy_entry => _hierarchy_entry, :ignore_translations => true }
      )
    ).compact
    @images = map? ? (@images[0..2] << map) : @images
    @images
  end

  # This is used by the TaxaController (and thus all its children) to help build information for ALL translations:
  def hierarchy_provider
    classifcation_filter? ? _hierarchy_entry.hierarchy_provider : nil
  end

  def scientific_name
    hierarchy_entry_or_taxon_concept.title_canonical_italicized
  end

  # NOTE - Seems like a bit of a waste to get the count and not save it, but I don't think we use the counts.
  def synonyms?
    classifcation_filter? ? _hierarchy_entry.scientific_synonyms.length > 0 :
      taxon_concept.count_of_viewable_synonyms > 0
  end

  def can_be_reindexed?
    return false if _hierarchy_entry
    return false unless user.min_curator_level?(:master)
    !taxon_concept.classifications_locked?
  end

  def can_set_exemplars?
    return false if _hierarchy_entry
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

  def details(options = {})
    @details ||= details_text_for_user
    options[:exclude_toc_item] ?
      @details.select { |d| !d.toc_items.include?(options[:exclude_toc_item]) } :
      @details
  end

  def toc(options = {})
    @toc_items ||= TocItem.table_of_contents_for_text(details)
    options[:under] ?
      @toc_items.select { |toc_item| toc_item.parent_id == options[:under].id } :
      @toc_items
  end

  def toc_roots
    @toc_roots ||= toc.dup.delete_if(&:is_child?)
  end

  # TODO - This belongs on TaxonNames or the like:
  # TODO - rewrite EOL::CommonNameDisplay to make use of TaxonPage... and to not suck.
  # options are just passed along to EOL::CommonNameDisplay.
  def common_names(options = {})
    return @common_names if @common_names
    if _hierarchy_entry
      names = EOL::CommonNameDisplay.find_by_hierarchy_entry_id(hierarchy_entry.id, options)
    else
      names = EOL::CommonNameDisplay.find_by_taxon_concept_id(taxon_concept.id, nil, options)
    end
    @common_names = names.select {|name| name.known_language? }
    @common_names
  end

  # TODO - This belongs in TaxonMedia or the like:
  # NOTE - _hierarchy_entry can be nil
  def facets
    @facets ||= EOL::Solr::DataObjects.get_aggregated_media_facet_counts(
      taxon_concept.id, :filter_hierarchy_entry => _hierarchy_entry, :user => user
    )
  end

  # TODO - This belongs in TaxonMedia
  # NOTE - we use this instance var in #preload_overview...
  # NOTE - Once you call this (with options), those options are preserved and you cannot call this with different
  # options. Be careful. (In practice, this never matters.)
  def media(options = {})
    @media ||= taxon_concept.data_objects_from_solr(options.merge(
      :ignore_translations => true,
      :filter_hierarchy_entry => hierarchy_entry,
      :return_hierarchically_aggregated_objects => true,
      :skip_preload => true,
      :preload_select => { :data_objects => [ :id, :guid, :language_id, :data_type_id, :created_at ] }
    ))
  end

  def media_count
    @media_count ||= taxon_concept.media_count(user, _hierarchy_entry)
  end

  # TODO - This belongs on TaxonConceptOverview
  def summary_text
    @summary_text ||= taxon_concept.overview_text_for_user(user) # NOTE - we use this instance var in #preload_overview.
  end

  def text(options = {})
    taxon_concept.text_for_user(user, options)
  end

  # TODO - this prolly belongs on TaxonConceptOverview, not here, but I'm not sure...
  def image
    taxon_concept.exemplar_or_best_image_from_solr(_hierarchy_entry)
  end

  # helper.link_to "foo", app.overview_taxon_path(taxon_page) # Results depend on hierarchy_entry:
  # => "<a href=\"/pages/910093/hierarchy_entries/16/overview\">foo</a>"
  # OR
  # => "<a href=\"/pages/910093/overview\">foo</a>"
  def to_param
    classifcation_filter? ? "#{taxon_concept.to_param}/hierarchy_entries/#{_hierarchy_entry.to_param}" :
                            taxon_concept.to_param
  end

  # TODO - Clearly this belongs in TaxonOverview...
  def preload_overview
    # TODO - this is a "magic trick" just to preload it along with the (real) media. Find another way:
    loadables = (media + [summary_text]).compact
    DataObject.replace_with_latest_versions!(loadables,
                                             :select => [ :description ], :language_id => user.language_id)
    includes = [ {
      :data_objects_hierarchy_entries => [ {
        :hierarchy_entry => [ :name, { :hierarchy => { :resource => :content_partner } }, :taxon_concept ]
      }, :vetted, :visibility ]
    } ]
    includes << { :all_curated_data_objects_hierarchy_entries =>
      [ { :hierarchy_entry => [ :name, :hierarchy, :taxon_concept ] }, :vetted, :visibility, :user ] }
    includes << :users_data_object
    includes << :license
    includes << { :agents_data_objects => [ { :agent => :user }, :agent_role ] }
    DataObject.preload_associations(loadables, includes)
    DataObject.preload_associations(loadables, :translations, :conditions => "data_object_translations.language_id=#{user.language_id}")
    @summary_text = loadables.pop if @summary_text # TODO - this is the other end of the proload magic. Fix.
    @media = loadables
  end

  # TODO - clearly this belongs in TaxonDetails...
  # NOTE - this assumes you have already called #media with whatever options you care to use.
  def preload_details
    # There should not be an older revision of exemplar image on the media tab. But recently there were few cases
    # found. Replace older revision of the exemplar image from media with the latest published revision.
    if image # If there's no exemplar image, don't bother...
      @media.map! { |m| (m.guid == image.guid && m.id != image.id) ? image : m }
    end
    DataObject.replace_with_latest_versions!(@media, :language_id => user.language_id)
    includes = [ {
      :data_objects_hierarchy_entries => [ {
        :hierarchy_entry => [ :name, :hierarchy, { :taxon_concept => :flattened_ancestors } ]
      }, :vetted, :visibility ]
    } ]
    includes << {
      :all_curated_data_objects_hierarchy_entries => [ {
        :hierarchy_entry => [ :name, :hierarchy, { :taxon_concept => :flattened_ancestors } ]
      }, :vetted, :visibility, :user ]
    }
    DataObject.preload_associations(@media, includes)
    DataObject.preload_associations(@media, :users_data_object)
    DataObject.preload_associations(@media, :language)
    DataObject.preload_associations(@media, :mime_type)
    DataObject.preload_associations(@media, :translations,
                                    :conditions => "data_object_translations.language_id = #{user.language_id}")
  end

private

  # Using the Rails codebase's convention of putting an underscore before the method name, here, because this isn't a
  # value you should ever be calling from outside this class... though we have a #hierarchy_entry method that you
  # *can* call. The difference is that this value can be nil (when no hierarchy_entry was passed into the
  # constructor). There are places, such as #hierarchy_entry_or_taxon_concept, where we need to know this, but only
  # privately. Outside of this class, you can test whether the entry was provided to the constructor using
  # #classifcation_filter?
  def _hierarchy_entry
    @_hierarchy_entry
  end

  def hierarchy_entry_or_taxon_concept
    _hierarchy_entry || taxon_concept
  end

  def map_taxon_concept
    @map_taxon_concept ||= classifcation_filter? ? _hierarchy_entry.taxon_concept : taxon_concept
  end

  # NOTE - the field aliases used in this query are required by #build_related_names_hash and are used in views.
  def get_related_names(which)
    from = which == :children ? 'he_child' : 'he_parent'
    other = which == :children ? 'he_parent' : 'he_child'
    filter = classifcation_filter? ? "id=#{_hierarchy_entry.id}" : "taxon_concept_id=#{taxon_concept.id}"
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
  def details_text_for_user(only_one = false)
    text_objects = taxon_concept.text_for_user(user,
      :language_ids => [ user.language_id ],
      :filter_by_subtype => true,
      :allow_nil_languages => user.default_language?,
      :toc_ids_to_ignore => TocItem.exclude_from_details.collect { |toc_item| toc_item.id },
      :per_page => (only_one ? 1 : 600) # NOTE - artificial limit of text objects here to increase the default 30
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
