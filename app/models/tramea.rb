class Tramea
  def self.summary_from_taxon_concept(taxon)
    id = taxon.id
    scientific_name = taxon.title
    common_names = taxon.preferred_common_names.map do |name|
      { "name": name.string, name.language.iso_639_1 }
    end
    image = taxon.published_exemplar_image
    {
      id: id,
      scientific_name: scientific_name,
      common_names: common_names,
      thumbnail: {
        "id" => image.id,
        "cache_id" => image.object_cache_url,
        "small_square" => image.thumb_or_object('88_88'),
        "square" => image.thumb_or_object('130_130'),
        "small" => image.thumb_or_object('98_68'),
        "large" => image.thumb_or_object
      }
    }.to_json
  end
  def self.image_from_data_object(image)
    raise "Needs to be an image" unless image.image?
    {
      "id" => image.id,
      "guid" => image.guid,
      "cache_id" => image.object_cache_url,
      "small_square" => image.thumb_or_object('88_88'),
      "square" => image.thumb_or_object('130_130'),
      "small" => image.thumb_or_object('98_68'),
      "large" => image.thumb_or_object,
      "title" => image.safe_object_title,
      "taxa" => image.data_object_taxa.map do |assoc|
        {
          "id": assoc.taxon_concept_id,
          "scientific_name": assoc.hierarchy_entry.name.string,
          "trusted": assoc.vetted_id == Vetted.trusted.id
          # TODO: It might be nice, here, to indicate who added the association, whether it was a ContentPartner or a curator
        }
      end
    }.to_json
  end
end
