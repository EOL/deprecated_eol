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
    TaxonConcept.preload_associations(taxon_concept, { :published_hierarchy_entries => :hierarchy })
    entries = taxon_concept.published_hierarchy_entries.select { |he| he.hierarchy.browsable? } # TODO - extract ...
        # though... don't we have a published_browsable_hierarchy_entries?
    entries = [hierarchy_entry] if hierarchy_entry && entries.empty?
  end

  def images
    @images ||= promote_exemplar_image(
      taxon_concept.images_from_solr(
        limit, { :filter_hierarchy_entry => hierarchy_entry, :ignore_translations => true }
      )
    )
  end

  # TODO - I would love it if this had a better name.
  def rel_canonical_href
    # YOU WERE HERE
  end

  def hierarchy_provider
    hierarchy_entry ? hierarchy_entry.hierarchy_label.presence : nil
  end

  def scientific_name
    # TODO - Why? hierarchy_entry has a title_canonical_italicized method which actually seems "smarter"... soooo...
    hierarchy_entry ? hierarchy_entry.italicized_name : taxon_concept.title_canonical_italicized
  end

  def can_be_reindexed?
    return false if hierarchy_entry
    return false unless user.min_curator_level?(:master)
    !taxon_concept.classifications_locked?
  end

  # TODO - git grep hierarchy_entry.rank_label  ... replace all of those with this:
  def classified_by
    entry.rank_label
  end

  # TODO - grep the project for more and fix
  def related_names
    hierarchy_entry ?
      TaxonConcept.related_names(:hierarchy_entry_id => hierarchy_entry.id) :
      TaxonConcept.related_names(:taxon_concept_id => taxon_concept.id)
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

  # Overriding this because it doesn't need to take the user anymore:
  def media_count
    taxon_concept.media_count(user)
  end

  # helper.link_to "foo", app.overview_taxon_path(taxon_page) # Results depend on hierarchy entry:
  # => "<a href=\"/pages/910093/hierarchy_entries/16/overview\">foo</a>"
  # OR
  # => "<a href=\"/pages/910093/overview\">foo</a>"
  def to_param
    hierarchy_entry ? "#{taxon_concept.to_param}/hierarchy_entries/#{hierarchy_entry.to_param}" :
                      "#{taxon_concept.to_param}"
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

end
