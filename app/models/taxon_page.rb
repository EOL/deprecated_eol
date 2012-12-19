# The information needed to build a taxon page: specifically, to filter all of the data appropriate to a user and an
# optional hierarchy.
#
# Put another way, this is an interface to the TaxonConcept that is aware of the 
class TaxonPage

  attr_reader :taxon_concept, :user, :hierarchy_entry

  def initialize(taxon_concept, user, hierarchy_entry = nil) 
    @taxon_concept = taxon_concept
    @user = user # TODO - we'll make more use of this later. For now, TaxonConcept uses it directly:
    @taxon_concept.current_user = @user
    @hierarchy_entry = hierarchy_entry || taxon_concept.entry
  end

  def entry
    hierarchy_entry
  end

  def hierarchy
    hierarchy_entry ? hierarchy_entry.hierarchy : taxon_concept.hierarchy
  end

  # We want to delegate damn near eveything to TaxonConcept... but don't want to maintain a list of those methods:
  # But note that we do NOT delegate the methods defined in this class (obviously), so pay attention to them!
  def method_missing(method, *args)
    if taxon_concept.respond_to?(method)
      puts "** :#{method} method was missing"
      class_eval { delegate method, :to => :taxon_concept } # Won't use method_missing next time!
      taxon_concept.send(method, args)
    else
      super
    end
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
    # TODO - need to recall how to build links from a model...
  end

  def hierarchy_provider
    hierarchy_entry ? hierarchy_entry.hierarchy_label.presence : nil
  end

  def scientific_name
    # TODO - Why? hierarchy_entry has a title_canonical_italicized method which actually seems "smarter"... soooo...
    hierarchy_entry ? hierarchy_entry.italicized_name : taxon_concept.title_canonical_italicized
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
