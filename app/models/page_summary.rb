class PageSummary < ActiveRecord::Base

  attr_accessible :id, :scientific_name, :image_key, :common_names
  # scientific_name, image_key, common_names. That's it.
  def self.from_concept(concept)
    commons = []
    concept.preferred_common_names.
            select { |pcn| pcn.language.activated_on }.
            each do |tcn|
      commons << "\"#{tcn.language.iso_639_1}\": "\
        "\"#{tcn.name.string.gsub(/"/, '""')}\""
    end
    commons = "{#{commons.join(",")}}"
    image = concept.exemplar_or_best_image_from_solr.try(:object_cache_url)
    if PageSummary.exists?(concept.id)
      summary = PageSummary.find(concept.id)
      summary.update_attributes(
        scientific_name: concept.title,
        image_key: image,
        common_names: commons.to_s)
    else
      PageSummary.create(
        id: concept.id,
        scientific_name: concept.title,
        image_key: image,
        common_names: commons.to_s)
    end
  end

  def self.from_ids(ids)
    TaxonConcept.where(id: ids).with_titles.find_each do |concept|
      from_concept(concept)
    end
  end

  def thumbnail
    DataObject.image_cache_path(image_key, '130_130')
  end

  def to_hash
    {
      id: id, scientific_name: scientific_name, image_key: image_key,
      common_names: JSON.parse(common_names), thumbnail: thumbnail
    }
  end
end
