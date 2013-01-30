# This represents the overview of a taxon concept, providing a minimal interface to only the aspects you might
# need to display one.
#
# Note this is somewhat similar to a TaxonPage (q.v.), but provides a much more minimal API for easier handling.
class TaxonOverview

  include TaxonPresenter # Covers initialization and the storing of those values passed in: tc, he, user.

  def top_media
    @images ||= promote_exemplar_image(
      taxon_concept.images_from_solr(
        map? ? 3 : 4, { :filter_hierarchy_entry => _hierarchy_entry, :ignore_translations => true }
      )
    ).compact
    @images = map? ? (@images[0..2] << map) : @images
    @images
  end

  def summary_text
    @summary_text ||= taxon_concept.overview_text_for_user(user) # NOTE - we use this instance var in #preload_overview.
  end

  def image
    taxon_concept.exemplar_or_best_image_from_solr(hierarchy_entry)
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

  # This is perhaps a bit too confusing: this checks if the *filtered* page really has a map (as opposed to whether
  # there is any map at all without filters):
  def map?
    map_taxon_concept.has_map? && map
  end

  # TODO - This should be called by a hook on #initialize.
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

  def cache_id
    "taxon_overview_#{taxon_concept.id}_#{user.language_abbr}"
  end

end
