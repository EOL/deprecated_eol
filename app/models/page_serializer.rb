class PageSerializer
  class << self
    # TODO:
    # * references. ...not for this version, but mark it as TODO.
    # * TODO attributions. Crappy. ...i think we can skip it for the very first version, but soon
    # * ratings are also TODO, though lower priority.
    # * TODO: Think about page content positions. :S
    # NOTE: I've been testing with: PageSerializer.store_page_id(328598)
    # Next was PageSerializer.store_page_id(1033083)
    # ...It's very slow. ...but that's EOL. :|
    def store_page_id(pid)
      name = Rails.root.join("public", "store-#{pid}.json").to_s
      File.unlink(name) if File.exist?(name)
      page = get_page_data(pid)
      EOL.log("Serialized #{pid}: Traits: #{page[:traits].size}, "\
        "media: #{page[:media].size}, "\
        "scientific_synonyms: #{page[:scientific_synonyms].size}, "\
        "vernaculars: #{page[:vernaculars].size}, "\
        "nonpreferred scientific names: #{page[:nonpreferred_scientific_names].size}, "\
        "collections: #{page[:collections].size}", prefix: ".")
      File.open(name, "w") { |f| f.puts(JSON.pretty_generate(page)) }
      File.chmod(0644, name)
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
      taxon_name = concept.title_canonical_italicized
      EOL.log("Serializing #{pid} (#{taxon_name})...", prefix: "#")
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
          sci_name = nil
          stat_m = nil
          sex = nil
          lifestage = nil
          trait_hash = {
            resource: build_resource(trait.resource),
            resource_pk: trait.uri.to_s.gsub(/.*\//, ""),
            predicate: build_uri(trait.predicate_uri)
          }
          trait.meta.each do |pred, vals|
            begin
              if pred.uri == "http://purl.org/dc/terms/source"
                src = vals.join(", ")
              elsif pred.uri == "http://rs.tdwg.org/dwc/terms/measurementUnit"
                # nothing
              elsif pred.uri == "http://rs.tdwg.org/dwc/terms/scientificName"
                sci_name = vals.join(", ")
              elsif pred.uri == "http://eol.org/schema/terms/statisticalMethod"
                stat_m = trait.statistical_method_names.join(", ")
              elsif pred.uri == "http://rs.tdwg.org/dwc/terms/lifeStage"
                lifestage = trait.life_stage_name # TODO: crap. This should really be a URI (I think).
              elsif pred.uri == "http://rs.tdwg.org/dwc/terms/sex"
                sex = trait.sex_name
              else
                predicate = build_uri(pred)
                vals.map do |value|
                  meta_hash = {
                    predicate: predicate
                  }
                  if value.is_a?(String)
                    meta_hash[:literal] = value
                  elsif value[:units]
                    meta_hash[:measurement] = value[:value]
                    meta_hash[:units] = build_uri(value[:units])
                  elsif value[:value].is_a?(KnownUri)
                    meta_hash[:term] = build_uri(value[:value])
                  end
                  trait_hash[:metadata] ||= []
                  trait_hash[:metadata] << meta_hash
                end
              end
            rescue NoMethodError => e
              # Nothing...
            end
          end
          trait_hash[:source] = src if src
          trait_hash[:scientific_name] = sci_name if sci_name
          trait_hash[:statistical_method] = stat_m if stat_m
          trait_hash[:sex] = sex if sex
          trait_hash[:lifestage] = lifestage if lifestage
          if trait.units_uri
            trait_hash[:measurement] = trait.value_name
            trait_hash[:units] = build_uri(trait.units_uri)
          elsif trait.value_uri.is_a?(KnownUri)
            trait_hash[:term] = build_uri(trait.value_uri)
          elsif trait.association? && ! trait.target_taxon.is_a?(MissingConcept)
            trait_hash[:object_page] = { id: trait.target_taxon.id,
              node: build_node(trait.target_taxon.entry, resource),
              scientific_name: trait.target_taxon_name,
              canonical_form: trait.target_taxon_name }
          else
            trait_hash[:literal] = trait.value_name
          end
          trait_hash
        end
      end

      page[:media] = []
      entries = concept.published_hierarchy_entries.select { |e| ! e.data_objects.empty? }
      entries.each do |entry|
        # entry = entries.first
        resource = build_resource(entry.hierarchy.resource)
        # NOTE: currently the slowest part of this process: having to dig
        # through all of this stuff rather than including it with the concept,
        # above: NOTE: this will NOT include relationships added by curators. I
        # don't care. This is just "test" data.
        images = entry.data_objects.select do |i|
          i.published? && i.data_type_id == DataType.image.id && ! i.is_subtype_map? && i.original_image
        end
        images ||= []
        images.each do |i|
          begin
            page[:media] << base_data_object_hash(i, resource, taxon_name,
              description: i.description_linked || i.description,
              base_url: i.original_image.sub("_orig.jpg", ""))
          rescue => e
            EOL.log("Unable to convert image #{i.id}, skipping: #{e.message}", prefix: "!")
          end
        end
      end

      page[:native_node] = build_node(node, resource)

      preferred_langs = {}
      page[:scientific_synonyms] = concept.scientific_synonyms.map do |sy|
        lang = get_language(sy)
        hash = { italicized: sy.name.italicized,
          canonical: sy.name.canonical_form.string,
          language: lang,
          preferred: sy.preferred? && ! preferred_langs[lang],
          trust: sy.vetted.label
        }
        preferred_langs[lang] = true if sy.preferred?
        hash
      end

      preferred_langs = {}
      page[:vernaculars] = concept.denormalized_common_names.map do |cn|
        lang = get_language(cn)
        hash = { string: cn.name.string,
          language: lang,
          preferred: cn.preferred? && ! preferred_langs[lang],
          trust: cn.vetted.label
        }
        preferred_langs[lang] = true if cn.preferred?
        hash
      end

      preferred_langs = {}
      page[:nonpreferred_scientific_names] = concept.nonpreferred_scientific_names.map do |sn|
        lang = get_language(sn)
        hash = { italicized: sn.name.italicized,
          canonical: sn.name.canonical_form.string,
          language: lang,
          preferred: false,
          trust: sn.vetted.label
        }
        hash
      end

      page[:articles] = []
      articles = get_all_articles(concept)
      if (articles && ! articles.empty?)
        articles.each do |article|
          resource = build_resource(article.resource)
          page[:articles] <<
            base_data_object_hash(article, resource, taxon_name,
              source_url: article.source_url,
              body: article.description_linked || article.description,
              sections: article.toc_items.map { |ti| build_section(ti) } )
        end
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
        resource = build_resource(map.resource)
        page[:maps] = [
          base_data_object_hash(map, resource, taxon_name,
            source_url: map.source_url,
            base_url: map.original_image.sub("_orig.jpg", ""))
        ]
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
      return nil if resource.is_a?(String)
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
      return nil if known_uri.is_a?(String)
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

    # TODO: it's re-reading those roles waaaaay too often. Cache.
    def build_attributions(data_object)
      attributions = []
      data_object.agents_data_objects.each do |attrib|
        url = nil
        url = attrib.agent.homepage if
          attrib.agent.homepage && attrib.agent.homepage =~ /^htt/
        attributions << { role: attrib.agent_role.label, url: url,
          value: attrib.agent.full_name }
      end
      attributions
    end

    def base_data_object_hash(i, resource, taxon_name, additional = {})
      attributions = build_attributions(i)
      lic = i.license || License.cc
      b_cit = i.bibliographic_citation
      b_cit = nil if b_cit.blank?
      { guid: i.guid,
        resource_pk: i.identifier,
        provider_type: "Resource",
        provider: resource,
        license: { name: lic.title, source_url: lic.source_url,
          icon_url: lic.logo_url, can_be_chosen_by_partners: lic.show_to_content_partners },
        language: get_language(i),
        bibliographic_citation: b_cit,
        rights_statement: i.rights_statement,
        location: {
          verbatim: i.location,
          lat: i.latitude,
          long: i.longitude,
          alt: i.altitude },
        attributions: attributions,
        owner: i.owner,
        name: i.best_title(taxon_name),
        source_url: i.source_url
      }.merge(additional)
    end

    # Yes, this is TERRIBLY inefficient and just copied from TaxonDetails. This
    # isn't critical code and I'm not worried about TaxonDetails changing before
    # this gets used. It was simpler than abstracting that class, sadly.
    def get_all_articles(concept)
      text_objects = concept.data_objects_from_solr(
        data_type_ids: DataType.text_type_ids,
        vetted_types: ['trusted', 'unreviewed', 'untrusted'],
        visibility_types: ['visible', 'invisible'],
        filter_by_subtype: true,
        allow_nil_languages: true,
        toc_ids_to_ignore: TocItem.exclude_from_details.map(&:id),
        per_page: 500
      )
      selects = {
        hierarchy_entries: [ :id, :rank_id, :identifier, :hierarchy_id, :parent_id, :published, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
        hierarchies: [ :id, :agent_id, :browsable, :outlink_uri, :label ],
        data_objects_hierarchy_entries: '*',
        curated_data_objects_hierarchy_entries: '*',
        data_object_translations: '*',
        table_of_contents: '*',
        info_items: '*',
        toc_items: '*',
        translated_table_of_contents: '*',
        users_data_objects: '*',
        resources: '*',
        content_partners: '*',
        refs: '*',
        ref_identifiers: '*',
        comments: 'id, parent_id',
        licenses: '*',
        users_data_objects_ratings: '*' }
      DataObject.preload_associations(text_objects, [ :users_data_objects_ratings, :comments, :license,
        { published_refs: { ref_identifiers: :ref_identifier_type } }, :translations, :data_object_translation, { toc_items: :info_items },
        { data_objects_hierarchy_entries: [ { hierarchy_entry: { hierarchy: { resource: :content_partner } } },
          :vetted, :visibility ] },
        { curated_data_objects_hierarchy_entries: :hierarchy_entry }, :users_data_object,
        { toc_items: [ :translations ] } ], select: selects)
      DataObject.sort_by_rating(text_objects, concept)
    end
  end
end
