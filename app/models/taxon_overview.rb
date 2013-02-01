# This represents the overview of a taxon concept, providing a minimal interface to only the aspects you might
# need to display one.
#
# Note this is somewhat similar to a TaxonPage (q.v.), but provides a much more minimal API for easier handling.
class TaxonOverview

  def classifications_count
    @classifications_count ||= taxon_concept.hierarchy_entries.length
  end

  def top_media
    @images ||= promote_exemplar_image(
      taxon_concept.images_from_solr(
        map? ? 3 : 4, { :filter_hierarchy_entry => _hierarchy_entry, :ignore_translations => true }
      )
    ).compact
    @images = map? ? (@images[0..2] << map) : @images
    @images
  end

  def details?
    details_text_for_user(:only_one)
  end

  def summary?
    !summary.blank?
  end

  def summary
    @summary ||= taxon_concept.overview_text_for_user(user) # NOTE - we use this instance var in #preload_overview.
  end

  def image
    taxon_concept.exemplar_or_best_image_from_solr(hierarchy_entry)
  end

  def collections
    # NOTE - -relevance was faster than either #reverse or rel * -1.
    @collections ||= all_collections.sort_by { |c| [ -c.relevance ] }[0..2]
  end

  def collections_count
    all_collections.count
  end

  # TODO - should we cache this?  Seems expensive for something that won't change often. It seems simple (to me) to at least denormalize the member count on the community
  # model itself, which would save us the bigger query here. ...But that would be in addition to caching the results for this overview.
  def top_communities
    # communities are sorted by the most number of members - descending order
    community_ids = taxon_concept.communities.map(&:id).compact
    return [] if community_ids.blank?
    member_counts = Member.select("community_id").group("community_id").where(["community_id IN (?)", community_ids]).
      order('count_community_id DESC').count
    return taxon_concept.communities if member_counts.blank?
    communities_sorted_by_member_count = member_counts.keys.map { |collection_id| taxon_concept.communities.detect { |c| c.id == collection_id } }
    best_three = communities_sorted_by_member_count[0..2]
    Community.preload_associations(best_three, :collections, :select => { :collections => :id })
    return best_three
  end

  def communities_count
    taxon_concept.communities.count
  end

  def curators
    taxon_concept.data_object_curators
  end

  def activity_log
    @log ||= taxon_concept.activity_log(:per_page => 5)
  end

  def map
    return @map if @map
    map_results = get_one_map
    @map = map_results.blank? ? nil : map_results.first
  end

  # The International Union for Conservation of Nature keeps a status for most known species, representing how
  # endangered that species is.  This will default to "unknown" for species that are not being tracked.
  def iucn_status
    iucn.description
  end

  def iucn_url
    iucn.source_url
  end

  def iucn?
    !iucn_conservation_status.blank?
  end

  # This is perhaps a bit too confusing: this checks if the *filtered* page really has a map (as opposed to whether
  # there is any map at all without filters):
  def map?
    map_taxon_concept.has_map? && map
  end

  # TODO - This should be called by a hook on #initialize.
  def preload_overview
    # TODO - this is a "magic trick" just to preload it along with the (real) media. Find another way:
    loadables = (media + [@summary]).compact
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
    @summary = loadables.pop if @summary # TODO - this is the other end of the proload magic. Fix.
    @media = loadables
  end

  def cache_id
    "taxon_overview_#{taxon_concept.id}_#{user.language_abbr}"
  end

private

  def all_collections
    @all_collections ||= taxon_concept.collections.published.watch
  end

  def iucn
    return @iucn if @iucn
    # TODO - rewrite query ... move to new class, perhaps?
    iucn_objects = DataObject.find(:all, :joins => :data_objects_taxon_concepts,
      :conditions => "`data_objects_taxon_concepts`.`taxon_concept_id` = #{taxon_concept.id}
        AND `data_objects`.`data_type_id` = #{DataType.iucn.id} AND `data_objects`.`published` = 1",
      :order => "`data_objects`.`id` DESC")
    my_iucn = iucn_objects.empty? ? nil : iucn_objects.first
    @iucn = my_iucn.nil? ? DataObject.new(:source_url => 'http://www.iucnredlist.org/about', :description => I18n.t(:not_evaluated)) : my_iucn
  end

end
