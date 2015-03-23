# This is a class used by Tramea.
# TODO: Because this class has denormalized attributes, it needs to be re-built when:
# * The exemplar image changes
# * An image is rated higher than other images on the page and there is no exemplar
# * A common name is preferred
# * A preferred common name is curated or deleted
# * The taxon_concept is moved / moved to
# * The preferred entry is harvested
class Summary < ActiveRecord::Base
  belongs_to :taxon_concept # ...which has_one :summary
  belongs_to :thumbnail, class_name: "DataObject", foreign_key: "data_object_id"

  has_and_belongs_to_many :common_names

  validates :taxon_concept_id, uniqueness: true

  def self.from_taxon_concept(taxon)
    return find_by_taxon_concept_id(taxon.id) if
      exists?(taxon_concept_id: taxon.id)
    summary = create(
      taxon_concept_id: taxon.id,
      scientific_name: taxon.entry.name.string,
    )
    summary.common_names = taxon.preferred_common_names.map do |tcn|
      CommonName.from_taxon_concept_name(tcn)
    end
    if image = taxon.published_exemplar_image
      summary.thumbnail = image
      summary.thumbnail_cache_id = image.object_cache_url
    end
  end

  def square_thumbnail
    DataObject.image_cache_path(thumbnail_cache_id, '88_88')
  end

  def thumbnail
    DataObject.image_cache_path(thumbnail_cache_id, '98_68')
  end

  def large_square_thumbnail
    DataObject.image_cache_path(thumbnail_cache_id, '130_130')
  end

  def large_thumbnail
    DataObject.image_cache_path(thumbnail_cache_id)
  end
end
