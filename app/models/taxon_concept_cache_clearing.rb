# This is kind of lame. It would be best if we logged somewhere which keys have ACTUALLY been written for a given
# taxon concept, but that's expensive and probably not worth the effort.  So we've extracted the logic here to
# "remember" which keys (might) exist for a taxon concept and to allow us to clear them all with one interaction:
class TaxonConceptCacheClearing

  attr_reader :taxon_concept

  def self.clear(taxon_concept)
    TaxonConceptCacheClearing.new(taxon_concept).clear
  end

  # TODO - this should really be for an association, not a combo of these two:
  def self.clear_for_data_object(taxon_concept, data_object)
    TaxonConceptCacheClearing.new(taxon_concept).clear_for_data_object(data_object)
  end 

  def initialize(taxon_concept)
    @taxon_concept = taxon_concept
  end

  # TODO - do we want a more generic name for methods, here? :call, :invoke, :run, :go ? ...I'll decide later.
  def clear
    clear_exemplars
    clear_media_counts
  end

  # TODO - refactor and test. Not in that order. I did only the most obvious cleanup, here.
  def clear_for_data_object(data_object)
    if data_object.data_type.label == 'Image'
      TaxonConceptExemplarImage.delete_all(:taxon_concept_id => @taxon_concept.id, :data_object_id => data_object.id)
      if cached_taxon_exemplar = Rails.cache.read(TaxonConcept.cached_name_for("best_image_id_#{@taxon_concept.id}")) &&
        cached_taxon_exemplar != "none"
        Rails.cache.delete(TaxonConcept.cached_name_for("best_image_id_#{@taxon_concept.id}")) if
          DataObject.find(cached_taxon_exemplar).guid == data_object.guid
      end
      clear_media_counts
      @taxon_concept.published_browsable_hierarchy_entries.each do |pbhe|
        if cached_taxon_he_exemplar =
          Rails.cache.read(TaxonConcept.cached_name_for("best_image_id_#{@taxon_concept.id}_#{pbhe.id}")) &&
          cached_taxon_he_exemplar != "none"
          Rails.cache.delete(TaxonConcept.cached_name_for("best_image_id_#{@taxon_concept.id}_#{pbhe.id}")) if
            cached_taxon_he_exemplar.guid == data_object.guid
        end
      end
    end
  end

private

  def associated_entries
    taxon_concept.hierarchy_entries
  end

  def clear_exemplars
    Language.find_active.each do |lang|
      Rails.cache.delete(TaxonConcept.cached_name_for("best_article_id_#{taxon_concept.id}_#{lang.id}"))
    end
    Rails.cache.delete(TaxonConcept.cached_name_for("best_image_id_#{taxon_concept.id}"))
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
