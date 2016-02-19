# This is kind of lame. It would be best if we logged somewhere which keys have ACTUALLY been written for a given
# taxon concept, but that's expensive and probably not worth the effort.  So we've extracted the logic here to
# "remember" which keys (might) exist for a taxon concept and to allow us to clear them all with one interaction:
class TaxonConceptCacheClearing

  attr_reader :taxon_concept

  def self.clear(taxon_concept)
    TaxonConceptCacheClearing.new(taxon_concept).clear
  end

  def self.clear_exemplar_image(taxon_concept)
    TaxonConceptCacheClearing.new(taxon_concept).clear_exemplar_image
  end

  # TODO - this should really be for an Association, not a combo of these two:
  def self.clear_for_data_object(taxon_concept, data_object)
    TaxonConceptCacheClearing.new(taxon_concept).clear_for_data_object(data_object)
  end

  def self.clear_overview_article_by_id(tc_id)
    Language.find_active.each do |lang|
      Rails.cache.delete(TaxonConcept.cached_name_for("best_article_id_#{tc_id}_#{lang.id}"))
    end
  end

  def initialize(taxon_concept)
    @taxon_concept = taxon_concept
  end

  def clear
    clear_preferred_entry
    clear_media_counts
    clear_images
    Rails.cache.delete(PageTraits.cache_key(@taxon_concept.id))
  end

  # TODO - test
  # NOTE - this can take a long time if there are many media!
  def self.clear_media(taxon_concept)
    # NOTE - needs to pass in a curator (any type will do); nothing is logged as being from that user, so this is okay:
    media = TaxonMedia.new(taxon_concept, User.curators.first, per_page: 1000).each do |dato|
      DataObject.find(dato).update_solr_index # Find needed because it doesn't have all attributes otherwise.
    end
  end

  # Pseudo-alias to allow one or many:
  def clear_for_data_object(data_object)
    clear_for_data_objects([data_object])
  end

  # TODO - refactor and test. Not in that order. I did only the most obvious cleanup, here. And it clearly needs more.  :|
  def clear_for_data_objects(data_objects)
    data_objects.compact.each do |data_object|
      # Allows more things to be passed in, like TaxonConceptExemplarImage:
      data_object = data_object.data_object if data_object.respond_to?(:data_object)
      next if data_object.nil? # Strange to do this twice, but we have to because of the previous line. :\
      if data_object.data_type.label == 'Image'
        clear_if_guid_matches("best_image_id_#{@taxon_concept.id}", data_object)
        @taxon_concept.published_browsable_hierarchy_entries.each do |pbhe|
          clear_if_guid_matches("best_image_id_#{@taxon_concept.id}_#{pbhe.id}", data_object)
        end
      end
    end
    clear_media_counts
  end

  def clear_exemplar_image
    Rails.cache.delete(TaxonConcept.cached_name_for("best_image_id_#{taxon_concept.id}"))
  end

private

  def associated_entries
    taxon_concept.hierarchy_entries
  end

  def clear_preferred_entry
    TaxonConceptCacheClearing.clear_overview_article_by_id(taxon_concept.id)
    clear_exemplar_image
    TaxonConceptPreferredEntry.destroy_all(taxon_concept_id: taxon_concept.id)
    ctcpe = taxon_concept.published_taxon_concept_preferred_entry
    taxon_concept.create_preferred_entry(ctcpe.hierarchy_entry) if ctcpe
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

  # Titles of images can be dependant on the (prefered classification's scientific) names of taxa:
  def clear_images
    taxon_concept.images_from_solr.each { |img| DataObjectCaching.clear(img) }
  end

  def clear_if_guid_matches(key, data_object)
    cached_exemplar = Rails.cache.read(TaxonConcept.cached_name_for(key))
    if cached_exemplar && cached_exemplar != "none"
      cached_dato = DataObject.find(cached_exemplar) rescue nil
      Rails.cache.delete(TaxonConcept.cached_name_for(key)) if cached_dato && cached_dato.guid == data_object.guid
    end
  end

end
