class PageSerializer
  class << self
    # TODO:
    # * references. ...not for this version, buy mark it as TODO.
    # * TODO attributions. Crappy. ...i think we can skip it for the very first version, but soon
    # * ratings are also TODO, though lower priority.
    # * TODO: Think about page content positions. :S
    # NOTE: I've been testing with: PageSerializer.store_page_id(328598)
    # Next was pid = 19831
    # ...It's very slow. ...but that's EOL. :|
    def store_page_id(pid)
      name = Rails.root.join("public", "store-#{pid}.json").to_s
      File.unlink(name) if File.exist?(name)
      page = get_page_data(pid)
      File.open(name, "w") { |f| f.puts(JSON.pretty_generate(page)) }
    end

    def get_page_data(pid)
      user = EOL::AnonymousUser.new(Language.default)
      # First, get it with supercedure:
      concept = TaxonConcept.find(pid)
      # Then, get it with includes:
      concept = TaxonConcept.where(id: concept.id).
        includes(
          :collections,
          published_hierarchy_entries: [ data_objects:
            [ :data_object_translation, :agents_data_objects, { license: :translated_license } ],
            hierarchy: { resource: :content_partner } ],
          preferred_common_names: [ name: [ canonical_form: :name ], language: :translated_language ],
          preferred_entry: [ hierarchy_entry: [ :rank, hierarchy: [ :resource ],
            flattened_ancestors: [ ancestor: [ name: [ canonical_form: :name ] ] ],
            name: [ :ranked_canonical_form, canonical_form: :name ] ] ]
        ).first
      # Test with pid = 328598 (Raccoon)
      # Or with pid = 1033083 (House Centipede)
      page = { id: concept.id, moved_to_node_id: nil }
      node = concept.entry
      resource = build_resource(node.hierarchy.resource)

      pt = PageTraits.new(concept.id)
      pt.populate
      traits = pt.traits
      if traits.blank?
        page[:traits] = []
      else
        page[:traits] = traits.map do |trait|
          src = nil
          trait_hash = {
            resource: build_resource(trait.resource),
            resource_pk: trait.uri.to_s.gsub(/.*\//, ""),
            predicate: build_uri(trait.predicate_uri),
            metadata: trait.meta.flat_map do |pair|
              if pair.first.uri == "http://purl.org/dc/terms/source"
                src = pair.second.join(",")
                next
              end
              predicate = build_uri(pair.first)
              pair.second.map do |value|
                meta_hash = {
                  predicate: predicate
                }
                if value.is_a?(String) &&
                  meta_hash[:literal] = value
                elsif value[:units]
                  meta_hash[:measurement] = value[:value]
                  meta_hash[:units] = build_uri(value[:units])
                elsif value[:value].is_a?(KnownUri)
                  meta_hash[:term] = build_uri(value[:value])
                end
                meta_hash
              end
            end.compact
          }
          trait_hash[:source] = src if src
          if trait.units_uri
            trait_hash[:measurement] = trait.value_name
            trait_hash[:units] = build_uri(trait.units_uri)
          elsif trait.value_uri.is_a?(KnownUri)
            trait_hash[:term] = build_uri(trait.value_uri)
          elsif trait.association?
            trait_hash[:object_page_id] = trait.target_taxon.id
          else
            trait_hash[:literal] = trait.value_name
          end
          trait_hash
        end
      end

      taxon_name = concept.title_canonical_italicized
      page[:media] = []
      entries = concept.published_hierarchy_entries.select { |e| ! e.data_objects.empty? }
      entries.each do |entry|
        # entry = entries.first
        resource = build_resource(entry.hierarchy.resource)
        # NOTE: currently the slowest part of this process: having to dig
        # through all of this stuff rather than including it with the concept,
        # above:
        images = entry.data_objects.select do |i|
          i.published? && i.data_type_id == DataType.image.id
        end
        puts "*" * 100
        puts "Entry #{entry.id}"
        images.each do |i|
          # i = images.first
          puts "Image #{i.id}"
          lic = i.license
          b_cit = i.bibliographic_citation
          b_cit = nil if b_cit.blank?
          url = i.original_image.sub("_orig.jpg", "")
          # NOTE: this will NOT include relationships added by curators. I don't
          # care. This is just "test" data.
          page[:media] << { guid: i.guid,
            resource_pk: i.identifier,
            provider_type: "Resource",
            provider: resource,
            license: { name: lic.title, source_url: lic.source_url,
              icon_url: lic.logo_url, can_be_chosen_by_partners: lic.show_to_content_partners },
            language: get_language(i),
            # TODO: skipping location here
            bibliographic_citation: b_cit,
            owner: i.owner,
            name: i.best_title(taxon_name),
            source_url: i.source_url,
            description: i.description_linked || i.description,
            base_url: url
          }
        end
      end

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
          body: article.description_linked || article.description,
          sections: article.toc_items.map { |ti| build_section(ti) }
        }]
      end

      page[:collections] = concept.collections.map do |col|
        { name: col.name,
          description: col.description,
          icon: col.logo_url
        }
      end

      if concept.page_feature && concept.page_feature.map_json?
        page[:json_map] = true
      end

      map = concept.get_one_map_from_solr.first
      if map
        lic = map.license
        b_cit = map.bibliographic_citation
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
      return page
    end

    def cached(key, id, &block)
      @caches ||= {}
      @caches[key] ||= {}
      return @caches[key][id] if @caches[key].has_key?(id)
      @caches[key][id] = yield
    end

    def get_language(object)
      return "eng" unless object.language_id
      cached(:languages, object.language_id) do
        if object.language
          l_code = object.language.iso_639_3
          l_code.blank? ? "eng" : l_code
        else
          "eng"
        end
      end
    end

    def build_resource(resource)
      return nil if resource.nil?
      cached(:resources, resource.id) do
        { name: resource.title, partner: resource.content_partner.name }
      end
    end

    def build_node(node, resource)
      return nil unless node
      cached(:nodes, node.id) do
        {
          resource: resource,
          node_id: node.id,
          rank: node.rank.try(:label),
          page_id: node.taxon_concept_id,
          scientific_name: node.italicized_name,
          canonical_form: node.title_canonical_italicized,
          resource_pk: node.identifier,
          source_url: node.source_url,
          parent: build_node(node.parent, resource)
        }
      end
    end

    def build_section(toc_item)
      return nil if toc_item.nil?
      cached(:sections, toc_item.id) do
        { parent: build_section(toc_item.parent), position: toc_item.view_order,
          name: toc_item.label }
      end
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
        cached(:uris, known_uri.id) do
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
end
