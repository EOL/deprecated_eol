# This is an interface to the TaxonConcept that is aware of the user and whether the user wants to see data from a
# single partner or not. This is the basis for may of the taxon_concept resources that are exposed on EOL.
#
# NOTE - when you call #initialize, the TaxonConcept is *immediately* loaded, if it wasn't already... so if you're
# counting on ARel to handle lazy loading, you will want to attach any selects and includes *before* calling
# TaxonPage.
#
# NOTE - as you write descendants of this class, please DO NOT rely on the #method_missing!  Please.  We want to
# eventually remove that. Where needed, call your methods striaght from #taxon_concept.
class TaxonUserClassificationFilter

  attr_reader :taxon_concept, :user

  def initialize(taxon_concept, user, hierarchy_entry = nil) 
    @taxon_concept = taxon_concept
    @user = user
    @taxon_concept.current_user = user # TODO - do we need this anymore?
    @_hierarchy_entry = hierarchy_entry
    after_initialize
  end

  # You could say TaxonUserClassificationFilter has_a overview.  :)
  # NOTE - what is a little odd is that an Overview now has an #overview (inherited).  ...Which is... weird... but hey.
  def overview
    TaxonOverview.new(taxon_concept, user, _hierarchy_entry)
  end

  def details
    TaxonDetails.new(taxon_concept, user, _hierarchy_entry)
  end

  # NOTE - *THIS IS IMPORTANT* ... when you see "_hierarchy_entry", it means "the one specified by initialize." When
  # you see "hierarchy_entry" (no leading underscore) it means "do the right thing".
  def hierarchy_entry
    _hierarchy_entry || @taxon_concept.entry
  end

  # This tells you whether the presenter is being viewed with a classification filter. ...Of course. Please don't
  # trust the return value to be the actual HE; you should only be using this for t/f tests.
  def classification_filter?
    _hierarchy_entry
  end

  # All permutations of presenters need to know how to name themselves:
  def scientific_name
    hierarchy_entry_or_taxon_concept.title_canonical_italicized
  end

  # helper.link_to "foo", app.taxon_overview_path(taxon_page) # Results depend on hierarchy_entry:
  # => "<a href=\"/pages/910093/hierarchy_entries/16/overview\">foo</a>"
  # OR
  # => "<a href=\"/pages/910093/overview\">foo</a>"
  def to_param
    classification_filter? ? "#{taxon_concept.to_param}/hierarchy_entries/#{_hierarchy_entry.to_param}" :
                            taxon_concept.to_param
  end

  def gbif_map_id
    map_taxon_concept.gbif_map_id
  end

  # NOTE - this checks if the *filtered* page really has a map (as opposed to whether there is any map at all):
  def map?
    map_taxon_concept.has_map? && map
  end

  def map_taxon_concept
    @map_taxon_concept ||= classification_filter? ? _hierarchy_entry.taxon_concept : taxon_concept
  end

  # NOTE - Once you call this (with options), those options are preserved and you cannot call this with different
  # options. Be careful. (In practice, this never matters.)
  def media(options = {})
    @media ||= taxon_concept.data_objects_from_solr(options.merge(
      :ignore_translations => true,
      :filter_hierarchy_entry => _hierarchy_entry,
      :return_hierarchically_aggregated_objects => true,
      :skip_preload => true,
      :preload_select => { :data_objects => [ :id, :guid, :language_id, :data_type_id, :created_at, :mime_type_id,
                                              :object_cache_url, :object_url, :data_rating ] }
    ))
  end

  def hierarchy
    classification_filter? ? _hierarchy_entry.hierarchy : taxon_concept.hierarchy
  end

  def kingdom
    classification_filter? ? _hierarchy_entry.kingdom : hierarchy_entry.kingdom
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

  # TODO - see if this can/should be moved. ATM, it's definitely needed by TaxonOverview (called through inheritance)...
  # Also used in these... should it be?
  # app/controllers/taxa/names_controller.rb:    @hierarchy_entries = @taxon_page.hierarchy_entries
  # app/views/taxa/_classification_selector.html.haml:    = f.select :id, options_from_collection_for_select(@taxon_page.hierarchy_entries, :id, 'hierarchy_label',
                                                                                                           # @taxon_page.h
  # app/views/taxa/_classification_tree.html.haml:  - count = @taxon_page.hierarchy_entries.length
  # app/views/taxa/names/_menu.html.haml:      = link_to I18n.t(:classifications_with_count, :count => @taxon_page.hierarchy_entries.length),
  # app/views/taxa/names/synonyms.html.haml:      - @taxon_page.hierarchy_entries.each do |he|
  # spec/models/taxon_user_classification_filter.rb:    @taxon_page.hierarchy_entries.should == []
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

  # This is used by the TaxaController (and thus all its children) to help build information for ALL translations:
  def hierarchy_provider
    classification_filter? ? _hierarchy_entry.hierarchy_provider : nil
  end

  # NOTE - We don't ever use the counts, so they are not saved here.
  def synonyms?
    classification_filter? ? _hierarchy_entry.scientific_synonyms.length > 0 :
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

  def rank_label
    hierarchy_entry_or_taxon_concept.rank_label
  end

  def related_names
    @related_names ||=
      {'parents' => build_related_names_hash(get_related_names(:parents)),
       'children' => build_related_names_hash(get_related_names(:children))}
  end

  def related_names_count
    related_names['parents'].count + related_names['children'].count
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

  def media_count
    @media_count ||= taxon_concept.media_count(user, _hierarchy_entry)
  end

  def image
    taxon_concept.exemplar_or_best_image_from_solr(_hierarchy_entry)
  end

  def text(options = {})
    taxon_concept.text_for_user(user, options)
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
  # *can* call. The difference is that _this value can be nil (when no hierarchy_entry was passed into the
  # constructor). There are places, such as #hierarchy_entry_or_taxon_concept, where we need to know this, but only
  # privately. Outside of this class, you can test whether the entry was provided to the constructor using
  # #classification_filter?
  def _hierarchy_entry
    @_hierarchy_entry
  end

  def hierarchy_entry_or_taxon_concept
    _hierarchy_entry || taxon_concept
  end

  # NOTE - the field aliases used in this query are required by #build_related_names_hash and are used in views.
  def get_related_names(which)
    from = which == :children ? 'he_child' : 'he_parent'
    other = which == :children ? 'he_parent' : 'he_child'
    filter = classification_filter? ? "id=#{_hierarchy_entry.id}" : "taxon_concept_id=#{taxon_concept.id}"
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

protected # You can only call these from the classes that inherit from TaxonUserClassificationFilter

  def after_initialize
    # Do nothing. If you inherit from the class, you'll want to override this.
  end

end
