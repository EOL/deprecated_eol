# This is a class used by Tramea. Note it's not an AR::B class, which is why the
# name is plural.
class Media
  def self.common_params_from_data_object(data)
    { data_object_id: data.id,
      guid: data.guid,
      language: data.language.iso_639_1,
      title: data.object_title.
      pages_in_media: pages_in_media_from_data_object(data)
    }.merge(License.params_from_data_object(data)).
      merge(UsersDataObjectsRating.params_from_data_object(data))
  end

  def self.add_common_associations_from_data_object(data, medium)
    medium.contents = data.data_object_taxa.map do |dot|
      Content.from_data_object_taxon(dot, medium)
    end
    medium.references = Ref.from_data_object(data, medium)
    medium.credits = Credit.from_data_object(data, medium)
  end

  def self.pages_in_media_from_data_object(data)
    pages = []
    data.associations.each do |assoc|
      pages << { id: assoc.taxon_concept_id, name: assoc.taxon_concept.title }
    end
    pages.to_json
  end

end
