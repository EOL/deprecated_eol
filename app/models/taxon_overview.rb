# This represents the overview of a taxon concept, providing a minimal interface to only the aspects you might
# need to display one.
#
# NOTE - this represents an OVERVIEW. It restricts the number of things it
# shows, so a method like #media does NOT give you the full list of media for
# the filtered taxon, it gives you the "overview" of them,  limited in number.
# I've tried to follow a pattern (usually) of having a "feature" (like #media)
# have a  method to return the subset (#media), tell you whether there are any
# at all (#details?) and return a count of the full list available
# (#classifications_count). There are exceptions; not all permutations were
# needed.
class TaxonOverview < TaxonUserClassificationFilter

  attr_accessor :media, :summary

  MEDIA_TO_SHOW = 4
  COLLECTIONS_TO_SHOW = 3
  COMMUNITIES_TO_SHOW = 3

  def classification
    hierarchy_entry.hierarchy
  end

  # NOTE - It should be "relatively impossible" for this to be nil. ...At least, TCs with no identifyable
  # entry should at least be unpublished (and thus not accessible on the site).
  def hierarchy_entry
    return _hierarchy_entry if classification_filter?
    return @entry if @entry
    if chosen = curator_chosen_classification
      @classification_chosen_by = chosen.user # Might as well set it while we have it.
      @entry = chosen.hierarchy_entry
    else
      @entry = hierarchy_entries.shuffle.first
      @entry ||= taxon_concept.deep_published_nonbrowsable_hierarchy_entries.shuffle.first
      @entry ||= super
    end
    @entry
  end
  alias_method :entry, :hierarchy_entry

  def classification_chosen_by
    return @classification_chosen_by if @classification_chosen_by
    chosen = curator_chosen_classification
    @classification_chosen_by = chosen ? chosen.user : nil
  end

  def classification_curated?
    @classification_curated ||= curator_chosen_classification
  end

  def classifications_count
    @classifications_count ||= taxon_concept.published_hierarchy_entries.length
  end

  def details?
    @has_details ||= taxon_concept.text_for_user(user,
      language_ids: [ user.language_id ],
      filter_by_subtype: true,
      allow_nil_languages: user.default_language?,
      toc_ids_to_ignore: TocItem.exclude_from_details.collect { |toc_item| toc_item.id },
      per_page: 1
    )
  end

  def summary?
    !@summary.blank?
  end

  def collections
    # NOTE - -relevance was faster than either #reverse or rel * -1.
    @collections ||= all_collections.sort_by { |c| [ -c.relevance ] }[0..COLLECTIONS_TO_SHOW-1]
  end

  def collections_count
    all_collections.count
  end

  # TODO - should we cache this?  Seems expensive for something that won't change often. It seems simple (to me) to at least
  # denormalize the member count on the community model itself, which would save us the bigger query here. ...But that would be
  # in addition to caching the results for this overview.
  def communities
    # communities are sorted by the most number of members - descending order
    community_ids = taxon_concept.communities.map(&:id).compact
    return [] if community_ids.blank?
    member_counts = Member.select("community_id").group("community_id").where(["community_id IN (?)", community_ids]).
      order('count_community_id DESC').count
    best_three = if member_counts.blank?
      taxon_concept.communities[0..COMMUNITIES_TO_SHOW-1]
                 else
      communities_sorted_by_member_count = member_counts.keys.map { |collection_id| taxon_concept.communities.detect { |c| c.id == collection_id } }
      communities_sorted_by_member_count[0..COMMUNITIES_TO_SHOW-1]
                 end
    Community.preload_associations(best_three, :collections, select: { collections: [:id, :collection_items_count] })
    return best_three
  end

  def communities_count
    taxon_concept.communities.count
  end

  def curators
    @curators ||= taxon_concept.data_object_curators
  end

  def curators_count
    @curators_count ||= curators.count
  end

  def activity_log
    @log ||= taxon_concept.activity_log(per_page: 5, user: user)
  end

  def map
    return @map if defined?(@map) # can be nil. :\
    @map = taxon_concept.get_one_map_from_solr.first
  end

  def iucn_status
    iucn.try(:description)
  end

  def iucn_url
    iucn.try(:source_url)
  end

  def cache_id
    "taxon_overview_#{taxon_concept.id}_#{user.language_abbr}"
  end

  def media # Note this replaces the #media method on TaxonUserClassificationFilter.
    @media
  end

private

  def after_initialize
    loadables = load_media.compact
    loadables << load_summary if load_summary
    TaxonUserClassificationFilter.preload_details(loadables, user)
    DataObject.preload_associations(loadables, { agents_data_objects: [ { agent: :user }, :agent_role ] })
    @summary = load_summary ? loadables.pop : nil
    @media = loadables
    correct_bogus_exemplar_image
  end

  def load_media
    media ||= promote_exemplar_image(
      taxon_concept.images_from_solr(
        map? ? MEDIA_TO_SHOW-1 : MEDIA_TO_SHOW,
        ignore_translations: true
      )
    ).compact
    media = media[0...MEDIA_TO_SHOW] if media.length > MEDIA_TO_SHOW
    media = media[0...MEDIA_TO_SHOW-1] << map if map?
    media
  end

  def load_summary
    taxon_concept.overview_text_for_user(user)
  end

  def all_collections
    @all_collections ||= published_containing_collections.select{ |c| !c.watch_collection? }
  end

  # NOTE this actully returns a taxon_concept_preferred_entry, not a "classification". TODO - rename.
  def curator_chosen_classification
    return @curator_chosen_classification if defined?(@curator_chosen_classification)
    @curator_chosen_classification = taxon_concept.published_taxon_concept_preferred_entry
  end

  # The International Union for Conservation of Nature keeps a status for most
  # known species, representing how endangered that species is.
  def iucn
    return @iucn if @iucn
    @iucn = taxon_concept.iucn
  end

  # NOTE - if the exemplar was not in data_objects, we'll end up with a longer list. ...Is this dangerous?
  def promote_exemplar_image(data_objects)
    return data_objects unless taxon_concept.published_exemplar_image
    data_objects.delete_if { |d| d.guid == taxon_concept.published_exemplar_image.guid }
    data_objects.unshift(DataObject.find(taxon_concept.published_exemplar_image))
    data_objects
  end

end
