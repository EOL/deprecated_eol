# This is kind of lame. It would be best if we logged somewhere which keys have ACTUALLY been written for a given
# taxon concept, but that's expensive and probably not worth the effort.  So we've extracted the logic here to
# "remember" which keys (might) exist for a taxon concept and to allow us to clear them all with one interaction:
class TaxonConceptCacheClearing

  attr_reader :taxon_concept

  def self.clear(taxon_concept)
    TaxonConceptCacheClearing.new(taxon_concept).clear
  end

  def initialize(taxon_concept)
    @taxon_concept = taxon_concept
  end

  # TODO - do we want a more generic name for methods, here? :call, :invoke, :run, :go ? ...I'll decide later.
  def clear
    clear_exemplars
    clear_media_counts
  end

private

  def associated_entries
    taxon_concept.hierarchy_entries
  end

  def clear_exemplars
    Rails.cache.delete(TaxonConcept.cached_name_for("best_article_id_#{taxon_concept.id}"))
    Rails.cache.delete(TaxonConcept.cached_name_for("best_image_#{taxon_concept.id}"))
  end

  def clear_media_counts
    Rails.cache.delete(TaxonConcept.cached_name_for("maps_count_#{taxon_concept.id}"))
    Rails.cache.delete(TaxonConcept.cached_name_for("media_count_#{taxon_concept.id}"))
    Rails.cache.delete(TaxonConcept.cached_name_for("media_count_#{taxon_concept.id}_curator"))
    associated_entries.map(&:id).each do |entry|
      Rails.cache.delete(TaxonConcept.cached_name_for("media_count_#{taxon_concept.id}_#{entry}"))
      Rails.cache.delete(TaxonConcept.cached_name_for("media_count_#{taxon_concept.id}_#{entry}_curator"))
    end
  end

end
