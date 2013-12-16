# Everything you need to render the summary of a taxon.
#
# Also serves as a denormalized "kickstarter" for a taxon_concept, containing much of the DB info it will need to handle a great
# many methods.
#
# Q: when does this get populated? A: almost certainly the same way we do taxon entries
class TaxonSummary < ActiveRecord::Base

  attr_accessible :classification_summary, :default_common_name, :scientific_name,
    :taxon_concept, :taxon_concept_id,
    :entry, :entry_id,
    :rank, :rank_id,
    :image, :image_id

  belongs_to :taxon_concept
  belongs_to :entry, class_name: 'HierarchyEntry'
  belongs_to :rank
  belongs_to :image, class_name: 'DataObject'

  # A lot of the behavior comes directly from TaxonConcept:
  delegate :to_param, to: :taxon_concept # Allows you to build URLs with this object as if it were a taxon_concept

  # Don't bother with methods:
  alias_attribute :preferred_classification_summary, :classification_summary
  alias_attribute :collected_name, :scientific_name
  alias_attribute :exemplar_or_best_image_from_solr, :image

  validates_uniqueness_of :taxon_concept_id

  # This should populate all the fields and 
  # NOTE - we assume that source (as it is passed in) is populated with a preload_associations call which will make the following
  # efficient. ...Doing it here would be a mistake because we often populate these in batches and preloading associations one at
  # a time is inefficient.
  def self.populate(source)
    summary = TaxonSummary.find_or_create_by_taxon_concept_id(source.id)
    summary.update_attributes(
      scientific_name: source.collected_name,
      classification_summary: source.preferred_classification_summary,
      default_common_name: source.preferred_common_name_in_language(Language.default),
      entry: source.entry,
      rank: source.entry.rank,
      image: source.published_exemplar_image)
    summary
  end

  #TODO - something to clear an entry...

  def preferred_classification_summary?
    true # We'll always have one, if this class is created/used.
  end

  def preferred_common_name_in_language(lang)
    return default_common_name if lang == Language.default
    taxon_concept.preferred_common_name_in_language(lang)
  end

end
