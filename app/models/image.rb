# This is a class used by Tramea.
class Image < ActiveRecord::Base
  has_many :contents
  has_many :credits
  has_many :references

  def self.from_data_object(dato)
    raise "Must be an image" unless dato.image?
    return find_by_data_object_id(dato.id) if
      exists?(data_object_id: dato.id)
    image = create({
      cache_id: dato.object_cache_url,
      source_url: dato.source_url
    }.merge(Media.common_params_from_data_object(dato)))
    Media.add_common_associations_from_data_object(dato, article)
    image
  end
end
