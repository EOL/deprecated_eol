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
<<<<<<< Updated upstream
  def self.image_from_data_object(image)
    raise "Needs to be an image" unless image.image?
=======

  # NOTE: This is _almost_ enough to render a full data object page: all you
  # need are the activities and revisions. ...And, arguably, more information
  # about the associations.
  def self.image_from_data_object(image)
    raise "Must be an image" unless image.image?
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
          # TODO: It might be nice, here, to indicate who added the association, whether it was a ContentPartner or a curator
        }
      end
    }.to_json
  end
=======
          # TODO: It might be nice, here, to indicate who added the association,
          # whether it was a ContentPartner or a curator... though I don't think
          # that is critical enough to add now.
        }
      end,
    }.merge(license_hash_from_data_object(image)).to_json
  end

  # NOTE: The 'section' is alwyas in English; you'll have to look up
  # translations based on that string. Activities and revisions are stored
  # separately.
  def self.article_from_data_object(article)
    raise "Must be an article" unless article.article?
    {
      "id" => image.id,
      "guid" => image.guid,
      "title" => image.safe_object_title,

    }.to_json
  end

  # NOTE: To render a license logo, you'll need to use the url, but I think
  # that's fine.
  def self.license_hash_from_data_object(data)
    {
      "license" => data.license.source_url,
      "rights" => data.rights_statement_for_display,
      "rights_holder" => data.rights_holder_for_display,
      "ratings" => data.rating_summary.
        merge("weighted_average" => data.average_rating),
      "source_url" => ,
      "credits" => [
        {
          "name" => "BioImages - the Virtual Fieldguide (UK)",
          "role" => "Supplier",
          "url" => "http://eol.org/content_partners/246"
        },
        {"name" => "Ian Smith", "role" => "Compiler"}
      ]
    }
  end
>>>>>>> Stashed changes
end
