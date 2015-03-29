class Tramea
  class << self
    def summary_from_taxon_concept(taxon)
      id = taxon.id
      scientific_name = taxon.title
      common_names = taxon.preferred_common_names.map do |tcn|
        { "name" => tcn.name.string, "language" => tcn.language.iso_639_1 }
      end
      image = taxon.published_exemplar_image
      hash = {
        "id" => taxon.id,
        "scientific_name" => taxon.entry.name.string
      }
      if taxon.common_taxon_concept_name
        hash["common_name"] = common_name_from_taxon_concept_name(
          taxon.common_taxon_concept_name
        )
      end
      if image
        hash["thumbnail"] = {
          "id" => image.id,
          "cache_id" => image.object_cache_url,
          "small_square" => image.thumb_or_object('88_88'),
          "square" => image.thumb_or_object('130_130'),
          "small" => image.thumb_or_object('98_68'),
          "large" => image.thumb_or_object
        }
      else
        hash["thumbnail"] = {}
      end
      hash
    end

    # NOTE: This is the motherload: a taxon page!
    def page_from_taxon_concept(taxon, options = {})
      options["images_page"] ||= 1
      options["images_per_page"] ||= 4
      options["articles_page"] ||= 1
      options["articles_per_page"] ||= 1
      options["traits_page"] ||= 1
      options["traits_per_page"] ||= 10
      # NOTE: this sucks, need to load a fake data helper to make this work: THIS IS REALLY SLOW.
      data = TaxonData.new(taxon)
      hash = {
        "id" => taxon.id,
        # TODO: "curator" is a PLACEHOLDER, meant to show that, in the future,
        # when you're a curator and you want to see hidden content, JUST LOAD
        # TWO OF THESE, and show the differences. The other will have a
        # 'curator' of 'uncurated' (id 0). Simple. The question that remains, of
        # course, is how to store the relationship between a curated page and
        # its media.
        "curator" => {"id" => 1, "name" => "EOL Curation Team"},
        "node_ids" => taxon.hierarchy_entry_ids,
        "node" => node_from_hierarchy_entry(taxon.entry),
        # TODO: the map.
        "images" => {
          # TODO
          "page" => options["images_page"],
          "per_page" => options["images_per_page"],
          "total" => "TODO",
          # TODO: manage the exemplar image; it should be first.
          "images" => taxon.
            images_from_solr(
              options["images_per_page"],
              ignore_translations: true
            ).map { |image| image_from_data_object(image, taxon) }
        },
        "articles" => {
          # TODO
          "page" => options["articles_page"],
          "per_page" => options["articles_per_page"],
          "total" => "TODO",
          # TODO: handle paginatation rather than just the summary:
          "articles" => [
              # The user argument here doesn't matter, really (q.v.).
              article_from_data_object(taxon.overview_text_for_user(User.first),
                taxon)
            ]
        },
        # TODO - Add trait ranges.
        # TODO: handle pagination of traits rather than just the overview-y ones:
        "traits" => {
          # TODO
          "page" => options["traits_page"],
          "per_page" => options["traits_per_page"],
          "total" => data.distinct_predicates.count,
          "traits" => data.get_data.map do |datum|
            trait_from_data_point_uri(datum)
          end
        }
      }
      if options["common_names"]
        hash["common_names"] = taxon.common_names_cleaned_and_sorted.map do |name|
          common_name_from_taxon_concept_name(name)
        end
      else # Let's give them one common name, at least:
        hash["common_name"] = common_name_from_taxon_concept_name(
          taxon.common_taxon_concept_name
        )
      end
      hash["synonyms"] = synonyms_from_taxon_concept(taxon) if
        options["synonyms"]
      hash
    end

    # NOTE: This is _almost_ enough to render a full data object page: all you
    # need are the activities and revisions. ...And, arguably, more information
    # about the associations.
    def image_from_data_object(image, taxon = nil)
      raise "Must be an image" unless image.image?
      {
        "id" => image.id,
        "guid" => image.guid,
        "cache_id" => image.object_cache_url,
        "small_square" => image.thumb_or_object('88_88'),
        "square" => image.thumb_or_object('130_130'),
        "small" => image.thumb_or_object('98_68'),
        "large" => image.thumb_or_object,
        "title" => image.object_title,
        "source_url" => image.source_url,
        "taxa" => image.data_object_taxa.map do |assoc|
          {
            "id" => assoc.taxon_concept_id,
            "scientific_name" => assoc.hierarchy_entry.name.string,
            "trusted" => assoc.vetted_id == Vetted.trusted.id
            # TODO: It might be nice, here, to indicate who added the association, whether it was a ContentPartner or a curator
          }
        end
      }.merge(license_from_data_object(image)).
        merge(trust_from_curatable(image, taxon))
    end

    # NOTE: The 'sections' are always in English; you'll have to look up
    # translations based on those strings. Activities and revisions are stored
    # separately.
    def article_from_data_object(article, taxon = nil)
      raise "Must be an article" unless article.article?
      {
        "id" => article.id,
        "guid" => article.guid,
        "title" => article.object_title,
        "sections" => article.toc_items.map { |ti| ti.label }.compact,
        "language" => article.language.iso_639_1,
        # NOTE: I removed an autolink here (it wasn't working; seemed superfluous here anyway)
        # NOTE: Yes, I too am tearing my hair out:
        "body_html" => Sanitize.clean(
            article.description.balance_tags,
            Sanitize::Config::RELAXED
          ).fix_old_user_added_text_linebreaks(:wrap_in_paragraph => true),
        "references" => article.refs.map do |ref|
          ref.full_reference.balance_tags.add_missing_hyperlinks
          # NOTE: refs actually also have one or more optional "identifiers". I
          # don't think we need them, now that we have autolinks, so I am going to
          # ignore them entirely.
        end
      }.merge(license_from_data_object(article)).
        merge(trust_from_curatable(article, taxon))
    end

    # TODO: Eventually I would LOVE to add a key called "taxon_concept_history"
    # where we store entry ids with taxon_concept ids and the curator or process
    # name that associated the two (and a timestamp for the move).
    def node_from_hierarchy_entry(entry, options = {})
      hash = {
        "id" => entry.id,
        "taxon_concept_id" => entry.taxon_concept_id,
        "exemplar" =>
          TaxonConceptPreferredEntry.exists?(hierarchy_entry_id: entry.id),
        "scientific_name" => entry.name.string,
        "rank" => entry.rank.label.firstcap
      }
      return hash if options[:lite]
      hash.merge({
        "source" => {
          "content_partner_id" => entry.hierarchy.resource.content_partner_id,
          "resource_id" => entry.hierarchy.resource.id,
          "name" => entry.hierarchy.resource.title,
          "id" => entry.identifier,
          "url" => entry.outlink_url,
          "browsable_on_eol" => entry.hierarchy.browsable?
        },
        # TODO: It might be nice to group these by data type, actually:
        "data_ids" => entry.data_object_ids,
        "ancestors" => entry.ancestors.map do |ancestor|
          node_from_hierarchy_entry(ancestor, lite: true)
        end,
        "children" => entry.children.map do |child|
          node_from_hierarchy_entry(child, lite: true)
        end,
        "siblings" => entry.siblings.map do |sibling|
          node_from_hierarchy_entry(sibling, lite: true)
        end
      })
    end

    # NOTE: It's assumed you're calling this FROM a taxon_concept, so the TC
    # isn't part of the returned data.
    def common_name_from_taxon_concept_name(tcn)
      # NOTE: I'm duplicating logic from TaxaHelper#common_name_display_attribution
      sources = tcn.agents.map do |agent|
        if agent.user
          {
            "name" => agent.user.full_name,
            "type" => "user",
            "id" => agent.user.id
          }
        else
          # NOTE: I don't believe anyone will ever be able to use the agent id:
          { "name" => agent.full_name, "type" => "agent", "id" => agent.id }
        end
      end
      sources += tcn.hierarchies.map do |hierarchy|
        {
          "name" => hierarchy.resource.title,
          # NOTE: content_partner is a METHOD, not an association, here:
          "content_partner_id" => hierarchy.content_partner.id,
          "id" => hierarchy.resource.id,
          "type" => "resource"
        }
      end
      # OMG. ...If a name has no other attribution, it's considered to be uBio.
      # Yes, really. THIS IS SO LAME.  TODO: fix this in the db (then clean up
      # the code in the helper, at least)
      sources << { "name" => "uBio", "type" => "default" } if sources.empty?
      {
        "language" => tcn.language.iso_639_1,
        "name" => tcn.name.string,
        "sources" => sources,
        "trusted" => tcn.vetted_id == Vetted.trusted.id,
        "preferred" => tcn.preferred?
      }
    end

    def synonyms_from_taxon_concept(taxon)
      taxon.hierarchy_entries.map do |entry|
        {
          "source" => {
            "id" => entry.hierarchy.resource.id,
            # NOTE: content_partner is a METHOD, not an association, here:
            "content_partner_id" => entry.hierarchy.content_partner.id,
            "name" => entry.hierarchy.resource.title
          },
          "synonyms" => [
              { "name" => entry.name.string, "relationship" => "preferred" }
            ] + entry.scientific_synonyms.map do |syn|
              { "name" => syn.name.string,
                "relationship" => syn.synonym_relation ?
                  syn.synonym_relation.label :
                  "synonym"
              }
            end
        }
      end
    end

    def trait_from_data_point_uri(uri)
      meta = uri.get_metadata(Language.default)
      {
        "id" => uri.id,
        # This will be some representation of "occurrenceID", something like
        # #get_other_occurrence_measurements ...but just returning the id (which
        # it does NOT in that query, sigh).
        "occurence_id" => "TODO",
        "subject" => summary_from_taxon_concept(uri.taxon_concept),
        "predicate" => uri_from_known_uri(uri.predicate_known_uri),
        "object" => object_uri(uri),
        "source" => {
          "content_partner_id" => uri.resource.content_partner_id,
          "resource_id" => uri.resource_id,
          "name" => uri.resource.content_partner.display_name,
          "scientific_name" => meta.select { |m|
            m.predicate_uri == 'http://rs.tdwg.org/dwc/terms/scientificName' }
        },
        "metadata" => meta.map do |data|
          {
            "predicate" => uri_from_known_uri(data.predicate_known_uri),
            "object" => object_uri(data)
          }
        end
      }
    end

    def object_uri(uri)
      uri.target_taxon_concept ?
        summary_from_taxon_concept(uri.target_taxon_concept) :
        uri.object_known_uri ?
          uri_from_known_uri(uri.object_known_uri) :
          uri.value_string(Language.english)
    end

    def trust_from_curatable(object, taxon = nil)
      hash = {}
      if taxon
        hash = {
          "trusted" => object.vetted_by_taxon_concept(taxon),
          "exemplar" => object.is_exemplar_for?(taxon)
        }
      else
        hash = {
          "trusted" => object.associations.any? { |a| a.trusted? },
          "exemplar" => object.respond_to?(:is_exemplar?) && object.is_exemplar?
        }
      end
      if hash["exemplar"]
        object.exemplar_chosen_by.each do |user|
          hash["exemplar_chosen_by"] ||= []
          hash["exemplar_chosen_by"] << {
            "id" => user.id,
            "name" => user.full_name
          }
        end
      end
      hash
    end

    # TODO: Examine this, but don't use it; it's too expensive. Rather, write a
    # query to look through all existing translations and update the data objects
    # affected. The way the original translation code is writen is ... "not
    # efficient". (╯°□°)╯︵ ┻━┻
    def translation_from_data_object(data)
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
    def license_from_data_object(data)
      {
        "license" => data.license.source_url,
        "rights" => data.rights_statement_for_display,
        "rights_holder" => data.rights_holder_for_display,
        "ratings" => data.rating_summary.
          merge("weighted_average" => data.average_rating),
        "credits" => [ # TODO
          {
            "name" => "BioImages - the Virtual Fieldguide (UK)",
            "role" => "Supplier",
            "url" => "http://eol.org/content_partners/246"
          },
        ]
      }
    end

    # NOTE: I am NOT translating these, so all "name" and "definition" values are
    # in English; that will have to be another UI.
    def uri_from_known_uri(uri)
      {
        "id" => uri.id,
        "name" => uri.name,
        "uri" => uri.uri,
        "definition" => uri.definition,
        "more_information" => [uri.ontology_source_url,
          uri.ontology_information_url].compact,
        "sections" => uri.toc_items.map { |ti| ti.label }.compact
      }
    end
  end
end
