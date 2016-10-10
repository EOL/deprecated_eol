class PageSerializer
  class << self
    # TODO:
    # * references. ...not for this version, buy mark it as TODO.
    # * TODO attributions. Crappy. ...i think we can skip it for the very first version, but soon
    # * ratings are also TODO, though lower priority.
    # * TODO: Think about page content positions. :S
    # NOTE: I've been testing with PageSerializer.store_page_id(328598).
    # Next was pid = 19831
    # ...It's very slow. ...but that's EOL. :|
    def store_page_id(pid)
      user = EOL::AnonymousUser.new(Language.default)
      # First, get it with supercedure:
      concept = TaxonConcept.find(pid)
      # Then, get it with includes:
      concept = TaxonConcept.where(id: concept.id).
        includes(
          :collections,
          preferred_common_names: [ name: [ canonical_form: :name ] ],
          preferred_entry: [ hierarchy_entry: [ :rank, hierarchy: [ :resource ],
            flattened_ancestors: [ ancestor: [ name: [ canonical_form: :name ] ] ],
            name: [ canonical_form: :name ] ] ]
        ).first
      # Test with pid = 328598 (Raccoon)
      page = { id: concept.id, moved_to_node_id: nil }
      node = concept.entry
      resource = build_resource(node.hierarchy.resource)

      page[:native_node] = build_node(node, resource)

      preferred_langs = {}
      page[:vernaculars] = concept.preferred_common_names.map do |cn|
        lang = get_language(cn)
        hash = { string: cn.name.string,
          language: lang,
          preferred: cn.preferred? && ! preferred_langs[lang]
        }
        preferred_langs[lang] = true if cn.preferred?
        hash
      end

      # Bah! Direct relationships were NOT working, so I'm using Solr, which is
      # horrible and indicates a deep problem. TODO: THIS WILL NOT WORK !!!
      # ...when you start grabbing higher-level taxa AND their children.
      # ...Well, it'll work... but it will contain many many duplicates.
      media = concept.data_objects_from_solr(
        ignore_translations: true,
        return_hierarchically_aggregated_objects: true,
        page: 1, per_page: 100,
        data_type_ids: DataType.image_type_ids )

      # NOTE: these were NOT pre-loaded, so we could limit them. Also note that
      # the curated_data_objects_hierarchy_entry CANNOT be preloaded here, since
      # it's invoked via GUID, not by ID (though the relationship could probably
      # be rewritten, that's out of scope, here.)
      page[:media] = media.map do |i|
        lic = i.license
        b_cit = i.bibliographic_citation
        b_cit = nil if b_cit.blank?
        url = i.original_image.sub("_orig.jpg", "")
        resource = build_resource(i.resource)
        { guid: i.guid,
          resource_pk: i.identifier,
          provider_type: "Resource",
          provider: resource,
          license: { name: lic.title, source_url: lic.source_url,
            icon_url: lic.logo_url, can_be_chosen_by_partners: lic.show_to_content_partners } ,
          language: get_language(i),
          # TODO: skipping location here
          bibliographic_citation: b_cit,
          owner: i.owner,
          name: i.best_title,
          source_url: i.source_url,
          description: i.description_linked,
          base_url: url
        }
      end

      article = concept.overview_text_for_user(user)
      if(article)
        lic = article.license
        b_cit = article.bibliographic_citation
        b_cit = nil if b_cit.blank?
        resource = build_resource(article.resource)
        page[:articles] = [{
          guid: article.guid,
          resource_pk: article.identifier,
          provider_type: "Resource",
          provider: resource,
          license: { name: lic.title, source_url: lic.source_url,
            icon_url: lic.logo_url, can_be_chosen_by_partners: lic.show_to_content_partners } ,
          language: get_language(article),
          # TODO: skipping location here
          bibliographic_citation: b_cit,
          owner: article.owner,
          name: article.best_title,
          source_url: article.source_url,
          body: article.description_linked,
          sections: article.toc_items.map { |ti| build_section(ti) }
        }]
      end

      traits = PageTraits.new(concept.id).traits
      page[:traits] = traits.map do |trait|
        source = trait.rdf_values("http://purl.org/dc/terms/source").map(&:to_s).
          find { |v| v !~ /resources\/\d/ }
        # TODO: metadata ...but we don't *need* it yet.
        trait_hash = {
          resource: build_resource(trait.resource),
          resource_pk: trait.uri.to_s.gsub(/.*\//, ""),
          predicate: build_uri(trait.predicate_uri),
          source: source
        }
        if trait.units_uri
          trait_hash[:measurement] = trait.value_name
          trait_hash[:units] = build_uri(trait.units_uri)
        elsif trait.value_uri.is_a?(KnownUri)
          trait_hash[:term] = build_uri(trait.value_uri)
        else
          trait_hash[:literal] = trait.value_name
          trait_hash[:object_page] = trait.target_taxon_uri
          trait_hash[:object_page_image] = trait.target_taxon_image
        end
        trait_hash
      end

      page[:collections] = concept.collections.map do |col|
        { name: col.name,
          description: col.description,
          icon: col.logo_url
        }
      end

      if concept.page_feature.map_json?
        page[:json_map] = true
      end

      map = concept.get_one_map_from_solr.first
      if map
        lic = article.license
        b_cit = article.bibliographic_citation
        b_cit = nil if b_cit.blank?
        resource = build_resource(map.resource)
        url = map.original_image.sub("_orig.jpg", "")
        page[:maps] = [{
          guid: map.guid,
          resource_pk: map.identifier,
          provider_type: "Resource",
          provider: resource,
          license: { name: lic.title, source_url: lic.source_url,
            icon_url: lic.logo_url, can_be_chosen_by_partners: lic.show_to_content_partners } ,
          language: get_language(map),
          bibliographic_citation: b_cit,
          owner: map.owner,
          name: map.best_title,
          source_url: map.source_url,
          base_url: url
        }]
      end

      name = Rails.root.join("public", "store-#{concept.id}.json").to_s
      File.unlink(name) if File.exist?(name)
      File.open(name, "w") { |f| f.puts(JSON.pretty_generate(page)) }
    end

    def get_language(object)
      return "eng" unless object.language
      l_code = object.language.iso_639_3
      l_code.blank? ? "eng" : l_code
    end

    def build_resource(resource)
      return nil if resource.nil?
      { name: resource.title, partner: resource.content_partner.name }
    end

    def build_node(node, resource)
      return nil unless node
      {
        resource: resource,
        rank: node.rank.label,
        page_id: node.taxon_concept_id,
        scientific_name: node.italicized_name,
        canonical_form: node.title_canonical_italicized,
        resource_pk: node.identifier,
        source_url: node.source_url,
        parent: build_node(node.parent, resource)
      }
    end

    def build_section(toc_item)
      return nil if toc_item.nil?
      { parent: build_section(toc_item.parent), position: toc_item.view_order,
        name: toc_item.label }
    end

    def build_uri(known_uri)
      return nil if known_uri.nil?
      if known_uri.is_a?(UnknownUri)
        { uri: known_uri.uri,
          name: known_uri.uri.sub(/^.*\//, "").underscore.humanize,
          description: "Information about this URI was not available during harvesting.",
          is_hidden_from_overview: true,
          is_hidden_from_glossary: true }
      else
        { uri: known_uri.uri,
          name: known_uri.name,
          definition: known_uri.definition,
          comment: known_uri.comment,
          attribution: known_uri.attribution,
          is_hidden_from_overview: known_uri.exclude_from_exemplars,
          is_hidden_from_glossary: known_uri.hide_from_glossary }
      end
    end
  end
end
