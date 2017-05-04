module Export
  class Clade
    # (4712200) => Tetrapoda (135_778)
    # (1642) => Mamalia (88_165)
    # (7662) => Carnivora (10_369)
    # (7665) => Procyonidae (695)

    # Export::Clade.save(7665)
    def self.save(id)
      Export::Clade.new(id).save
    end

    def initialize(id)
      @id = id
      @trusted = Vetted.trusted.id
      @visible = Visibility.visible.id
      @native = Hierarchy.itis.id
      @article_id = DataType.text.id
      @map_id = DataType.map.id
      @link_id = DataType.link.id
      @breadcrumb_rank_ids = ["kingdom", "phylum", "class_rank", "order",
        "family", "species", "subspecies"].map { |r| Rank.send(r).id }
      @english = Language.english.id
      @scientific_id = Language.scientific.id
      @gallery_id = ViewStyle.gallery.id

      @articles = []
      @attributions = []
      @bibliographic_citations = []
      @collections = []
      @collected_pages = []
      @collected_pages_media = []
      @collection_associations = []
      @content_sections = []
      @curations = []
      @languages = []
      @licenses = []
      @links = []
      @locations = []
      @media = []
      @nodes = []
      @occurrence_maps = []
      @pages = []
      @page_contents = []
      @page_icons = []
      @partners = []
      @ranks = []
      @references = []
      @referents = []
      @resources = []
      @roles = []
      @scientific_names = []
      @sections = []
      @taxonomic_statuses = []
      @terms = {} # NOTE this one is a hash because we need to search it by uri.
      @traits = []
      @users = []
      @vernaculars = []
    end

    def save

      # TODO: add curations, add links, add occurrence_maps

      # Concept IDs:
      concepts = TaxonConceptsFlattened.descendants_of(@id).
        map { |f| f.taxon_concept_id }
      concepts << @id # It should be in there, but juuuuust in case...
      supercedures = TaxonConcept.where(id: concepts).
        where("supercedure_id IS NOT NULL AND supercedure_id != 0").
        pluck(:supercedure_id)
      superceded = TaxonConcept.where(id: concepts).
        where("supercedure_id IS NOT NULL AND supercedure_id != 0").
        pluck(:id)
      concepts = TaxonConcept.where(id: concepts).
        where(published: true, vetted_id: @trusted).pluck(:id)
      concepts += supercedures unless supercedures.empty?

      # Sorry, I know this is cryptic, but... it's good Ruby, you should learn
      # it!  :D
      uri_types = Hash[*(TranslatedUriType.where(language_id: @english).all.
        flat_map { |u| [u.uri_type_id, u.name] })]

      toc_items = []

      # Let's just get the slow part (traits) out of the way first, sigh:
      concepts.each do |id|
        puts(".. superceded: #{id}") && next if superceded.include?(id)
        page_traits = PageTraits.new(id)
        page_traits.populate
        puts(".. NO TRAITS: #{id}") && next if page_traits.nil?
        if page_traits.glossary
          page_traits.glossary.each do |known_uri|
            comment = known_uri.comment || ""
            comment += "\nOntology Description: #{known_uri.ontology_information_url}" unless
              known_uri.ontology_information_url.blank?
            comment += "\nOntology Source: #{known_uri.ontology_source_url}" unless
              known_uri.ontology_source_url.blank?
            @terms[known_uri.uri] ||= {
              uri: known_uri.uri,
              is_hidden_from_overview: known_uri.exclude_from_exemplars,
              is_hidden_from_glossary: known_uri.hide_from_glossary,
              position: known_uri.position,
              type: uri_types[known_uri.uri_type_id],
              comment: comment,
              name: known_uri.name,
              section_ids: known_uri.toc_item_ids,
              definition: known_uri.definition,
              attribution: known_uri.attribution
            }
            toc_items += known_uri.toc_item_ids
          end
        else
          puts ".. NO GLOSSARY: #{id}"
        end
        traits = page_traits.instance_eval { @traits }
        if traits
          traits.each do |trait|
            next unless trait.visible?
            is_num = trait.value_name.is_numeric? && ! trait.predicate_uri.treat_as_string?
            val_num = if is_num
              if trait.value_name.is_float?
                trait.value_name.to_f
              else
                trait.value_name
              end
            else
              nil
            end
            metadata = []
            trait.meta.each do |pred, vals|
              vals.each do |val|
                val_uri = val.is_a?(KnownUri) ? val.uri : nil
                val_uri ||= val.is_a?(Hash) && val[:value].is_a?(KnownUri) ? val[:value].uri : nil
                units = val.is_a?(Hash) && val[:units].is_a?(KnownUri) ? val[:units].uri : nil
                units = val[:units] if val.is_a?(Hash)
                literal = val[:value] if val.is_a?(Hash) && ! val[:value].is_a?(KnownUri)
                literal ||= val unless val.is_a?(KnownUri)
                metadata << {
                  predicate: pred.is_a?(KnownUri) ? pred.uri : pred,
                  value_uri: val_uri,
                  value_literal: literal,
                  units: units
                }
              end
            end
            @traits << {
              predicate: trait.predicate_uri.uri,
              resource_id: trait.resource ? trait.point.resource_id : nil,
              resource_pk: trait.point.id, # This is not "real", but it will do for testing.
              association: trait.association,
              statistical_methods: trait.statistical_method? ? trait.statistical_method_names.join(", ") : nil,
              value_uri: trait.value_uri.is_a?(KnownUri) ? trait.value_uri.uri : nil,
              value_literal: trait.value_uri.is_a?(KnownUri) ? nil : trait.value_name,
              value_num: val_num,
              units: trait.units? ? trait.units_uri.uri : nil,
              sex: trait.sex ? trait.sex_name : nil,
              life_stage: trait.life_stage ? trait.life_stage_name : nil,
              source_url: trait.resource ? nil : trait.source_url,
              metadata: metadata
            }
          end
        else
          puts ".. NO TRAITS: #{id}"
        end
      end

      # Entry IDs:
      # NOTE: this will fail if it's missing, and that's fine:
      native_node = HierarchyEntry.where(taxon_concept_id: @id,
        hierarchy_id: @native).first
      entry_ids = HierarchyEntry.where(taxon_concept_id: concepts,
        published: true, vetted_id: @trusted, visibility_id: @visible).
        pluck(:id)
      entry_ids += native_node.ancestors.map(&:id)

      hes = HierarchyEntry.where(id: entry_ids).
        select([:id, :name_id, :rank_id, :hierarchy_id, :taxon_concept_id])
      names = hes.map(&:name_id)
      ranks = hes.map(&:rank_id)
      hierarchies = hes.map(&:hierarchy_id)

      # Synonyms of all sorts:
      synonyms = Synonym.where(hierarchy_entry_id: entry_ids,
        vetted_id: @trusted, published: true).pluck(:id)
      names += Synonym.where(id: synonyms).pluck(:name_id)
      names = names.uniq

      canonical_forms = CanonicalForm.where(name_id: names).pluck(:id)

      # First pass; only the taxa...
      c1 = CollectionItem.where(collected_item_type:
        "TaxonConcept", collected_item_id: concepts).
        pluck(:collection_id).uniq
      # Remove collections with too many items:
      collections = Collection.where(id: c1).
        where(["collection_items_count <= 100 AND special_collection_id IS NULL "\
          "AND published = ?", true]).pluck(:id)
      # Only the pages that are in our set of included pages...
      collection_items = CollectionItem.where(collected_item_type:
        "TaxonConcept", collected_item_id: concepts,
        collection_id: collections).pluck(:id)
      collection_items += CollectionItem.where(collection_id: collections).
        where(["collected_item_type IN (?)", ["DataObject", "Collection"]]).
        pluck(:id)

      # Include all the collected images:
      data_objects = CollectionItem.where(id: collection_items,
        collected_item_type: "DataObject").pluck(:collected_item_id)

      # These collections will be EMPTY, other than the name, but that's fine:
      collections += CollectionItem.where(id: collection_items,
        collected_item_type: "Collection").pluck(:collected_item_id)

      resources = Resource.where(hierarchy_id: hierarchies).pluck(:id)
      partners = Resource.where(id: resources).pluck(:content_partner_id)

      # NOTE we are NOT checking vetted/visible here (we want the hidden
      # associations) ... ALSO that these are OBJECTS, not ids!:
      dohes = DataObjectsHierarchyEntry.where(hierarchy_entry_id: entry_ids) ; 1
      cdohes = CuratedDataObjectsHierarchyEntry.where(hierarchy_entry_id: entry_ids) ; 1
      udos = UsersDataObject.where(taxon_concept_id: concepts) ; 1

      users = cdohes.map(&:user_id) + udos.map(&:user_id)

      data_objects += dohes.map(&:data_object_id) +
        cdohes.map(&:data_object_id) +
        udos.map(&:data_object_id) ; 1
      data_objects.compact.uniq
      articles = DataObject.where(id: data_objects, data_type_id: @article_id).
        pluck(:id)
      links = DataObject.where(id: data_objects, data_type_id: @link_id).
        pluck(:id)
      # maps = DataObject.where(id: data_objects, data_subtype_id: @map_id).
      #   pluck(:id)

      media = data_objects.dup
      media -= articles
      media -= links
      # media -= maps

      # SLOOOOOOOW query. NOTE these are whole objects, too:
      agents_data_objects = AgentsDataObject.
        where(data_object_id: data_objects).
        select("agents_data_objects.*, data_objects.id, "\
          "data_objects.data_type_id, agents.full_name, agents.homepage").
        includes([:agent, :data_object]) ; 1
      agents = agents_data_objects.map(&:agent_id).uniq
      roles = agents_data_objects.map(&:agent_role_id).uniq

      languages = DataObject.where(id: data_objects).pluck(:language_id) +
        Synonym.where(id: synonyms).pluck(:language_id)
      languages = languages.uniq
      licenses = Resource.where(id: resources).pluck(:license_id) +
        Resource.where(id: resources).pluck(:dataset_license_id) +
        DataObject.where(id: data_objects).pluck(:license_id)
      licenses = licenses.uniq

      infos = DataObjectsInfoItem.where(data_object_id: articles).pluck(:info_item_id).uniq
      toc_items += TocItem.where(id: InfoItem.where(id: infos).pluck(:toc_id)).pluck(:id)
      toc_items += TocItem.where(id: toc_items.uniq).pluck(:parent_id).compact
      toc_items = toc_items.uniq

      # TODO: traits! Yeesh.  Traits.

      TaxonConcept.where(id: concepts).includes(:taxon_concept_exemplar_image).
        find_each do |concept|
          medium_id = concept.taxon_concept_exemplar_image &&
            concept.taxon_concept_exemplar_image.data_object_id
          # NOTE: yes, this causes N queries and is inefficient. I don't want to
          # add a relationship to make it possible to skip this. It's not THAT
          # bad.
          native_node = HierarchyEntry.where(taxon_concept_id: concept.id,
            hierarchy_id: @native).pluck(:id).first
          @pages << { id: concept.id, medium_id: medium_id,
            moved_to_page_id: concept.supercedure_id,
            native_node_id: native_node }
        end

      HierarchyEntry.where(id: entry_ids).
        includes(hierarchy: :resource, name: :canonical_form).
        order(:id).
        find_each do |entry|
          @nodes << { id: entry.id,
            canonical_form: entry.name.canonical_form.string,
            has_breadcrumb: @breadcrumb_rank_ids.include?(entry.rank_id),
            page_id: entry.taxon_concept_id,
            # NOTE: we have to fake a lack of parents for nodes where we don't
            # have a parent; otherwise the import fails due to a missing parent.
            parent_id: entry_ids.include?(entry.parent_id) ? entry.parent_id : 0,
            rank_id: entry.rank_id,
            resource_id: entry.hierarchy.resource.id,
            resource_pk: entry.identifier,
            scientific_name: entry.name.italicized,
            source_url: entry.source_url }
        end


      TranslatedRank.where(rank_id: ranks, language_id: @english).
        find_each do |trank|
          @ranks << { id: trank.rank_id, name: trank.label } # treat_as calculated on import.
        end

      Resource.where(id: resources).includes(:hierarchy).find_each do |resource|
        @resources << {
          dataset_license_id: resource.dataset_license_id,
          dataset_rights_holder: resource.dataset_rights_holder,
          dataset_rights_statement: resource.dataset_rights_statement,
          description: resource.description,
          has_duplicate_nodes: resource.hierarchy.complete,
          id: resource.id,
          is_browsable: resource.hierarchy.browsable,
          last_publish_seconds: resource.last_harvest_seconds,
          last_published_at: resource.harvested_at,
          name: resource.title,
          nodes_count: resource.hierarchy.hierarchy_entries_count,
          notes: resource.notes,
          partner_id: resource.content_partner_id,
          url: resource.hierarchy.url
        }
      end

      Synonym.where(id: synonyms).
        where(["synonym_relation_id IN (?)", SynonymRelation.common_name_ids]).
        includes(:name, :hierarchy_entry).find_each do |syn|
          lang = syn.language_id
          lang = @english if lang == 0
          @vernaculars << {
            id: syn.id,
            # is_preferred: syn.preferred, # Really this needs to be handled on import.
            is_preferred_by_resource: syn.preferred,
            language_id: lang,
            node_id: syn.hierarchy_entry_id,
            page_id: syn.hierarchy_entry.taxon_concept_id,
            string: syn.name.string,
            trust: syn.vetted_id = @trusted ? :trusted : :untrusted
          }
        end

      TranslatedSynonymRelation.where(synonym_relation_id:
        Synonym.where(id: synonyms).pluck(:synonym_relation_id).uniq).
        where(language_id: @english).find_each do |ts|
          @taxonomic_statuses << {
            id: ts.synonym_relation_id,
            name: ts.label
          }
        end

      Synonym.where(id: synonyms).
        where(["synonym_relation_id NOT IN (?)", SynonymRelation.common_name_ids]).
        includes(:hierarchy_entry, name: :canonical_form).find_each do |syn|
          @scientific_names << {
            canonical_form: syn.name.canonical_form.string,
            id: syn.id,
            is_preferred: syn.preferred,
            italicized: syn.name.italicized,
            node_id: syn.hierarchy_entry_id,
            page_id: syn.hierarchy_entry.taxon_concept_id,
            taxonomic_status_id: syn.synonym_relation_id
          }
        end

      Collection.where(id: collections).find_each do |col|
        # Note: No "list" view anymore:
        @collections << {
          collection_type: col.view_style_id == @gallery_id ? :gallery : :normal,
          description: col.description,
          id: col.id,
          name: col.name
        }
      end

      CollectionItem.where(id: collection_items,
        collected_item_type: "TaxonConcept").find_each do |item|
          @collected_pages << {
            annotation: item.annotation,
            collection_id: item.collection_id,
            id: item.id,
            page_id: item.collected_item_id,
            position: item.id # Totally fake. :(
          }
        end

      CollectionItem.where(id: collection_items,
        collected_item_type: "Collection").find_each do |item|
          @collection_associations << {
            annotation: item.annotation,
            collection_id: item.collection_id,
            id: item.id,
            associated_id: item.collected_item_id,
            position: item.id # Totally fake. :(
          }
        end

      collected_page_ids = {}
      @collected_pages.each { |cp| collected_page_ids[cp[:page_id]] = cp }

      CollectionItem.where(id: collection_items,
        collected_item_type: "DataObject").find_each do |item|
          # Yes, this is slow, but I want to be able to test these, sooo...
          tc = DataObjectsTaxonConcept.
            where(data_object_id: item.collected_item_id).
            pluck(:taxon_concept_id).first

          cp_id = if collected_page_ids.has_key?(tc)
            collected_page_ids[tc][:id]
          else
            @collected_pages << {
              annotation: "added via image",
              collection_id: item.collection_id,
              id: item.id,
              page_id: tc,
              position: item.id # Totally fake. :(
            }
            # Make sure we don't add the same page multiple times:
            collected_page_ids[tc] = @collected_pages.last
            item.id
          end

          @collected_pages_media << {
            collected_page_id: cp_id, medium_id: item.collected_item_id,
            position: item.id # fake
          }
        end

      ContentPartner.where(id: partners).find_each do |cp|
        shortest_name = cp.full_name[0..15]
        shortest_name += "..." if cp.full_name.length > 16
        @partners << {
          admin_notes: cp.admin_notes,
          description: cp.description,
          full_name: cp.full_name,
          short_name: cp.acronym || cp.display_name || shortest_name,
          homepage_url: cp.homepage,
          id: cp.id,
          notes: cp.notes
        }
      end

      he_ids = dohes.map(&:hierarchy_entry_id) +
        cdohes.map(&:hierarchy_entry_id)
      do_hes = {}
      do_n_hes = {}
      tcs = udos.map(&:taxon_concept_id)
      HierarchyEntry.where(id: he_ids.uniq).find_each do |he|
        do_hes[he.id] = he
        tcs << he.taxon_concept_id
      end
      HierarchyEntry.where(hierarchy_id: @native, taxon_concept_id: tcs.uniq).
        includes(:flat_ancestors).find_each do |he|
          do_n_hes[he.taxon_concept_id] = he
        end

      dohes.each do |dohe|
        type = get_type(dohe.data_object.data_type_id)
        source_page_id = do_hes[dohe.hierarchy_entry_id].taxon_concept_id
        trust = dohe.vetted_id == @trusted ? :trusted : :untrusted
        hid = dohe.visibility_id != @visible
        @page_contents << {
          # association_added_by_user_id: _,
          content_id: dohe.data_object_id,
          content_type: type,
          # is_duplicate: _,
          is_hidden: hid,
          # is_incorrect: _,
          # is_low_quality: _,
          # is_misidentified: _,
          page_id: source_page_id,
          source_page_id: source_page_id,
          trust: trust
        }
        native_node = do_n_hes[source_page_id]
        next unless native_node
        native_node.flat_ancestors.each do |ancestor|
          @page_contents << {
            content_id: dohe.data_object_id,
            content_type: type,
            is_hidden: hid,
            page_id: ancestor.taxon_concept_id,
            source_page_id: source_page_id,
            trust: trust
          }
        end
      end

      # Yes, massive redundancy, but it's not worth abstracting now.
      cdohes.each do |dohe|
        type = get_type(dohe.data_object.data_type_id)
        source_page_id = do_hes[dohe.hierarchy_entry_id].taxon_concept_id
        trust = dohe.vetted_id == @trusted ? :trusted : :untrusted
        hid = dohe.visibility_id != @visible
        dupl = false
        incorr = false
        lowq = false
        misid = false
        if trust == :untrusted
          a = dohe.data_object.curator_activity_logs.
            where(activity_id: Activity.untrusted).last
          a.untrust_reasons.map { |r| r.label }.each do |lab|
            case lab
            when "misidentified"
              misid = true
            when "incorrect/misleading"
              incorr = true
            when "low quality"
              lowq = true
            when "duplicate"
              dupl = true
            end
          end
        elsif hid
          a = dohe.data_object.curator_activity_logs.
            where(activity_id: Activity.hide).last
          a.untrust_reasons.map { |r| r.label }.each do |lab|
            case lab
            when "misidentified"
              misid = true
            when "incorrect/misleading"
              incorr = true
            when "low quality"
              lowq = true
            when "duplicate"
              dupl = true
            end
          end
        end
        @page_contents << {
          association_added_by_user_id: dohe.user_id,
          content_id: dohe.data_object_id,
          content_type: type,
          is_duplicate: dupl,
          is_hidden: hid,
          is_incorrect: incorr,
          is_low_quality: lowq,
          is_misidentified: misid,
          page_id: source_page_id,
          source_page_id: source_page_id,
          trust: trust
        }
        users << dohe.user_id if dohe.user_id
        native_node = do_n_hes[source_page_id]
        next unless native_node
        native_node.flat_ancestors.each do |ancestor|
          @page_contents << {
            content_id: dohe.data_object_id,
            content_type: type,
            is_duplicate: dupl,
            is_hidden: hid,
            is_incorrect: incorr,
            is_low_quality: lowq,
            is_misidentified: misid,
            page_id: ancestor.taxon_concept_id,
            source_page_id: source_page_id,
            trust: trust
          }
        end
      end

      udos.each do |udo|
        type = get_type(udo.data_object.data_type_id)
        source_page_id = udo.taxon_concept_id
        @page_contents << {
          association_added_by_user_id: udo.user_id,
          content_id: udo.data_object_id,
          content_type: type,
          # is_duplicate: _,
          is_hidden: false,
          # is_incorrect: _,
          # is_low_quality: _,
          # is_misidentified: _,
          page_id: source_page_id,
          source_page_id: source_page_id,
          trust: :trusted
        }
        users << udo.user_id if udo.user_id
        native_node = do_n_hes[source_page_id]
        next unless native_node
        native_node.flat_ancestors.each do |ancestor|
          @page_contents << {
            content_id: udo.data_object_id,
            content_type: type,
            is_hidden: false,
            page_id: ancestor.taxon_concept_id,
            source_page_id: source_page_id,
            trust: :trusted
          }
        end
      end

      DataObject.where(id: articles).includes(:data_object_translation).
        find_each do |dato|
          has_cit = ! dato.bibliographic_citation.blank?
          has_loc = false
          has_loc = true if ! dato.location.blank?
          has_loc = true if ! dato.spatial_location.blank?
          has_loc = true if dato.latitude && dato.latitude != 0.0
          has_loc = true if dato.longitude && dato.longitude != 0.0
          has_loc = true if dato.altitude && dato.altitude != 0.0
          if has_cit
            @bibliographic_citations << {
              id: dato.id,
              body: dato.bibliographic_citation
            }
          end
          if has_loc
            @locations << {
              altitude: dato.altitude == 0.0 ? nil : dato.altitude,
              id: dato.id,
              latitude: dato.latitude == 0.0 ? nil : dato.latitude,
              location: dato.location,
              longitude: dato.longitude == 0.0 ? nil : dato.longitude,
              spatial_location: dato.spatial_location
            }
          end
          @articles << {
            bibliographic_citation_id: has_cit ? dato.id : nil,
            body: dato.description,
            guid: dato.guid,
            id: dato.id,
            language_id: dato.language_id,
            license_id: dato.license_id,
            location_id: has_loc ? dato.id : nil,
            name: dato.object_title,
            owner: dato.owner, # Expensive. :(
            resource_id: dato.identifier,
            rights_statement: dato.rights_statement,
            source_url: dato.source_url
          }
        end

      DataObjectsInfoItem.where(data_object_id: articles).
        includes(:info_item).find_each do |sec|
          @content_sections << {
            content_id: sec.data_object_id,
            content_type: "Article",
            section_id: sec.info_item.toc_id
          }
        end

      # TODO: links ...I think we are going live without them, soooo... skipped!

      # NOTE: I tried joining on HEvs here to find the resource ID and it was
      # too slow, so I'm doing it one at a time.
      DataObject.where(id: media).includes(:data_object_translation).
        find_each do |dato|
          has_cit = ! dato.bibliographic_citation.blank?
          has_loc = false
          has_loc = true if ! dato.location.blank?
          has_loc = true if ! dato.spatial_location.blank?
          has_loc = true if dato.latitude && dato.latitude != 0.0
          has_loc = true if dato.longitude && dato.longitude != 0.0
          has_loc = true if dato.altitude && dato.altitude != 0.0
          if has_cit
            @bibliographic_citations << {
              id: dato.id,
              body: dato.bibliographic_citation
            }
          end
          if has_loc
            @locations << {
              altitude: dato.altitude == 0.0 ? nil : dato.altitude,
              id: dato.id,
              latitude: dato.latitude == 0.0 ? nil : dato.latitude,
              location: dato.location,
              longitude: dato.longitude == 0.0 ? nil : dato.longitude,
              spatial_location: dato.spatial_location
            }
          end
          thumb = dato.thumb_or_object
          next unless thumb # Useless without an image...
          # RIDICULOUS. ...But if it's missing, we have to fake something:
          resouce_id = dato.resource.id || 1 rescue 1
          @media << {
            base_url: thumb.sub(/_580_360[^\/]*$/, ""),
            bibliographic_citation_id: has_cit ? dato.id : nil,
            description: dato.description,
            format: thumb.sub(/^.*_580_360\./, ""),
            guid: dato.guid,
            id: dato.id,
            language_id: dato.language_id,
            license_id: dato.license_id,
            location_id: has_loc ? dato.id : nil,
            name: dato.object_title,
            owner: dato.owner,
            resource_id: resource_id,
            resource_pk: dato.identifier,
            rights_statement: dato.rights_statement,
            source_page_url: dato.object_url,
            source_url: dato.source_url,
            subclass: dato.data_subtype_id == @map_id ? :map : :image
          }
        end

      agents_data_objects.each do |ado|
        type = get_type(ado.data_object.data_type_id)
        @attributions << {
          content_id: ado.data_object_id,
          content_type: type,
          role_id: ado.agent_role_id,
          url: ado.agent.homepage,
          value: ado.agent.full_name
        }
      end

      TranslatedAgentRole.where(agent_role_id: roles, language_id: @english).
        find_each do |role|
          @roles << {
            id: role.agent_role_id,
            name: role.label
          }
        end

      DataObjectsRef.where(data_object_id: media).all.each do |ref|
        @references << {
          referent_id: ref.ref_id,
          parent_type: "Medium",
          parent_id: ref.data_object_id
        }
      end

      PageFeature.where(taxon_concept_id: concepts, map_json: true).
        find_each do |map|
          @occurrence_maps << {
            page_id: map.taxon_concept_id,
            url: "not_worth_it" # This would be a complex query; not worth it for tests...
          }
        end

      DataObjectsRef.where(data_object_id: articles).find_each do |ref|
        @references << {
          referent_id: ref.ref_id,
          parent_type: "Article",
          parent_id: ref.data_object_id
        }
      end

      referents = DataObjectsRef.where(data_object_id: data_objects).
        pluck(:ref_id).uniq
      Ref.where(id: referents, visibility_id: @visible, published: true).
        find_each do |ref|
          @referents << {
            body: ref.full_reference
          }
        end

      Language.where(id: languages).find_each do |lang|
        @languages << {
          id: lang.id,
          code: lang.iso_639_2,
          group: lang.iso_639_1,
          can_browse_site: ! lang.activated_on.nil?
        }
      end

      License.where(id: licenses).find_each do |lic|
          @licenses << {
            can_be_chosen_by_partners: lic.show_to_content_partners,
            icon_url: lic.logo_url,
            id: lic.id,
            name: lic.title,
            source_url: lic.source_url,
          }
        end

      TranslatedTocItem.where(table_of_contents_id: toc_items,
        language_id: @english).includes(:toc_item).
        find_each do |tsec|
          @sections << {
            id: tsec.table_of_contents_id,
            name: tsec.label,
            parent_id: tsec.toc_item.parent_id,
            position: tsec.toc_item.view_order
          }
        end

      User.where(id: users.uniq).find_each do |user|
        @users << {
          id: user.id,
          username: user.username,
          name: user.full_name,
          tag_line: user.tagline,
          bio: user.bio,
          is_admin: user.is_admin?,
          api_key: user.api_key
        }
      end

      TaxonConceptExemplarImage.where(data_object_id: media).find_each do |img|
        @page_icons << {
          page_id: img.taxon_concept_id,
          medium_id: img.data_object_id
          # NOTE: we really want a user id here, but, alas, that's not worth
          # getting (where it's even possible)... :(
        }
      end

      name = Rails.root.join("public", "clade-#{@id}.json").to_s
      File.unlink(name) if File.exist?(name)
      summary = "Exporting Clade #{@id}: pages: #{@pages.size}, "\
        "traits: #{@traits.size}, media: #{@media.size} -> #{name}"
      puts summary
      EOL.log(summary, prefix: ".")
      File.open(name, "w") do |f|
        f.puts(JSON.pretty_generate(data))
      end
      File.chmod(0644, name)
      puts "Done."
    end

    def data
      {
        articles: @articles,
        attributions: @attributions,
        bibliographic_citations: @bibliographic_citations,
        collections: @collections,
        collected_pages: @collected_pages,
        collected_pages_media: @collected_pages_media,
        collection_associations: @collection_associations,
        content_sections: @content_sections,
        curations: @curations,
        languages: @languages,
        licenses: @licenses,
        links: @links,
        locations: @locations,
        media: @media,
        nodes: @nodes,
        occurrence_maps: @occurrence_maps,
        pages: @pages,
        page_contents: @page_contents,
        page_icons: @page_icons,
        partners: @partners,
        ranks: @ranks,
        references: @references,
        referents: @referents,
        resources: @resources,
        roles: @roles,
        scientific_names: @scientific_names,
        sections: @sections,
        taxonomic_statuses: @taxonomic_statuses,
        terms: @terms,
        traits: @traits,
        users: @users,
        vernaculars: @vernaculars
      }
    end

    def get_type(data_type_id)
      case data_type_id
      when @article_id
        "Article"
      when @map_id
        "Map"
      when @link_id
        "Link"
      else
        "Medium"
      end
    end
  end
end
