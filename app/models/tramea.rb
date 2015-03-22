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

  # NOTE: This is _almost_ enough to render a full data object page: all you
  # need are the activities and revisions. ...And, arguably, more information
  # about the associations.
  def self.image_from_data_object(image)
    raise "Must be an image" unless image.image?
    {
      "id" => image.id,
      "guid" => image.guid,
      "cache_id" => image.object_cache_url,
      "small_square" => image.thumb_or_object('88_88'),
      "square" => image.thumb_or_object('130_130'),
      "small" => image.thumb_or_object('98_68'),
      "large" => image.thumb_or_object,
      "title" => image.safe_object_title,
      "source_url" => image.source_url,
      "taxa" => image.data_object_taxa.map do |assoc|
        {
          "id": assoc.taxon_concept_id,
          "scientific_name": assoc.hierarchy_entry.name.string,
          "trusted": assoc.vetted_id == Vetted.trusted.id
          # TODO: It might be nice, here, to indicate who added the association, whether it was a ContentPartner or a curator
        }
      end
    }.merge(license_hash_from_data_object(image)).
      merge(trust_hash_from_curatable(image)).
      to_json
  end

  # NOTE: The 'sections' are always in English; you'll have to look up
  # translations based on those strings. Activities and revisions are stored
  # separately.
  def self.article_from_data_object(article)
    raise "Must be an article" unless article.article?
    {
      "id" => article.id,
      "guid" => article.guid,
      "title" => article.safe_object_title,
      "sections" => article.toc_items.map { |ti| ti.label }.compact,
      "language" => article.language.iso_639_1,
      # NOTE: Yes, I too am tearing my hair out:
      "body_html" => Sanitize.clean(
          auto_link(article.description).
          balance_tags, Sanitize::Config::RELAXED
        ).fix_old_user_added_text_linebreaks(:wrap_in_paragraph => true),
      "hey" => whatever
    }.merge(license_hash_from_data_object(article)).
      merge(trust_hash_from_curatable(article)).
      to_json
  end

  def self.trust_hash_from_curatable(object)
    hash = {
      "trusted" => object.vetted?,
      "exemplar" => object.respond_to?(:is_exemplar?) && object.is_exemplar?
    }
    if hash["exemplar"]
      object.exemplar_chosen_by.each do |user|
        hash["exemplar_chosen_by"] ||= []
        hash["exemplar_chosen_by"] << {
          "id" => user.id
          "name" => user.full_name,
        }
      end
    end
    hash
  end

  # TODO: Examine this, but don't use it; it's too expensive. Rather, write a
  # query to look through all existing translations and update the data objects
  # affected. The way the original translation code is writen is ... "not
  # efficient".
  def self.translation_hash_from_data_object(data)
    hash = {}
    # NOTE: translations are bloody ridiculous, but it is what it is. It uses
    # the User to filter in or out certain visibilities/vettedness, so I'm using
    # the admin user here to just get everything (for now).
    hash["translated_from_id"] = data.translated_from.id if data.translated_from
    translations = data.available_translations_data_objects(User.first, nil)
    return hash if translations.empty?
    trans = {}
    translations.map do |translation|
      trans[translation.language.iso_639_1] = translation.id
    end
    hash["translations"] = trans
    hash
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
end
