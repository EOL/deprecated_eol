# This is a class used by Tramea.
class Image < ActiveRecord::Base
  has_many :contents
  has_many :credits

  def self.from_data_object(dato, taxon = nil)
    raise "Must be an image" unless dato.image?
    return find(dato.id) if exists?(id: dato.id)
    ratings = dato.rating_summary
    image = create({
      id: dato.id,
      guid: dato.guid,
      cache_id: dato.object_cache_url,
      title: dato.object_title,
      source_url: dato.source_url,
      # TODO: extract this to some class, like with License.
      ratings_1: ratings[1],
      ratings_2: ratings[2],
      ratings_3: ratings[3],
      ratings_4: ratings[4],
      ratings_5: ratings[5],
      rating_weighted_average: data.average_rating
    }.merge(License.params_from_data_object(dato)))
    image.contents = dato.data_object_taxa.map do |dot|
      Content.from_data_object_taxon(dot, dato)
    end
    # Adds all credits; no need to assign it here:
    Credit.from_data_object(dato, image)
    image
  end
end
