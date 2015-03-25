# This is a class used by Tramea.
class Image < ActiveRecord::Base
  has_many :contents
  has_many :credits

  def self.from_data_object(dato, taxon = nil)
    raise "Must be an image" unless dato.image?
    return find_by_data_object_id(dato.id) if
      exists?(data_object_id: dato.id)
    image = create({
      data_object_id: dato.id,
      guid: dato.guid,
      cache_id: dato.object_cache_url,
      title: dato.object_title,
      source_url: dato.source_url
    }.merge(License.params_from_data_object(dato)).
      merge(UsersDataObjectsRating.params_from_data_object(dato)))
    image.contents = dato.data_object_taxa.map do |dot|
      Content.from_data_object_taxon(dot, dato)
    end
    # I don't know why images would have refs, but technically they can, (they
    # will render in the view) and there's no reason NOT to keep them, soooo...
    Ref.from_data_object(dato, image)
    Credit.from_data_object(dato, image)
    image
  end
end
