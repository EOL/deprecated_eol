class TraitBank
  class << self ; attr_reader :default_limit end
  @default_limit = 5000
  class << self
    # Stupid that this is hidden as much as it is:
    def prefixes
      EOL::Sparql.connection.send :namespaces_prefixes
    end

    def exists?(uri)
      r = EOL::Sparql.connection.query("SELECT COUNT(*) { <#{uri}> ?o ?p }")
      return false unless r.first && r.first.has_key?(:"callret-0")
      r.first[:"callret-0"].to_i > 0
    end

    # Returns an Set (not an array!) of which uris DO exist.
    def group_exists?(uris)
      exist = Set.new
      uris.to_a.in_groups_of(1000, false) do |group|
        begin
          resp = EOL::Sparql.connection.query("SELECT DISTINCT(?s) { ?s ?o ?p } "\
            "FILTER ( ?s IN (<#{uris.join(">,<")}>) )")
          exist += resp.map { |u| u[:s].to_s }
        rescue EOL::Exceptions::SparqlDataEmpty => e
          # Nothing to add.
        end
      end
      exist
    end

    def graph_name
      "http://eol.org/traitbank"
    end

    def delete_traits(traits)
      # TODO: you need to make a query that will find all "?s dc:source
      # <#{graph_name}>", and then delete all triples with that subject, but
      # filtering out anything that's "?s a eol:page". Yeesh.
      traits.in_groups_of(1000, false) do |group|

      end
    end

    # NOTE: CAREFUL! If you are running the data live, this will destroy all
    # data before it begins and you will have NO DATA ON THE SITE. This is meant
    # to be a _complete_ rebuild, run in emergencies!
    def rebuild
      EOL.log_call
      EOL.log("Prefixes, for convenience:", prefix: ".")
      EOL.log(prefixes, prefix: ".")
      # Ruh-roh. After some number of triples (about a million, which comes
      # quickly!), a command like this takes too long, and it times out, and
      # nothing works. :\
      # EOL::Sparql.connection.query("CLEAR GRAPH <#{graph_name}>")
      taxa = Set.new
      begin
        Resource.where("harvested_at IS NOT NULL").find_each do |resource|
          count = resource.trait_count
          EOL.log("#{resource.title} (#{resource.id}): #{count}")
          # Rebuild this one if there are any triples in the (old) graph:
          taxa += rebuild_resource(resource) if count > 0
        end
      ensure
        # This could be QUITE a lot... many millions. :\
        flatten_taxa(taxa)
      end
      EOL.log_return
    end

    # TODO: the problem is that the mappings graphs appear to be mucked up! So,
    # bypass them here. :\ We'll have to call HierarchyEntry.where(hierarchy_id:
    # 1502, identifier: identifier).taxon_concept_id on each identifier (which
    # you get by pulling off ... the start of the taxonId URL). This sucks, but
    # it's a reasonable workaround. Not sure why this happened!
    def rebuild_resource(resource)
      EOL.log_call
      # TODO: Ideally, we would first get a diff of what's in the graph vs what
      # we're going to put in the graph, and add the new stuff and remove the
      # old. That's a lot of work! Not doing that now.
      triples = []
      taxa = Set.new
      taxon_re = /^.*\/(\d+)$/
      traits = Set.new
      paginate(measurements_query(resource)) do |results|
        results.each do |h|
          raise "No value for #{h[:trait]}!" unless h[:value]
          taxa << h[:page].to_s.sub(taxon_re, "\\1")
          triples << "<#{h[:page]}> a eol:page ; "\
            "<#{h[:predicate]}> <#{h[:trait]}>"
          triples << "<#{h[:trait]}> a eol:trait"
          add_meta(triples, h, "http://rs.tdwg.org/dwc/terms/measurementValue",
            :value, literal: true)
          add_meta(triples, h, "http://rs.tdwg.org/dwc/terms/measurementUnit",
            :units)
          add_meta(triples, h, "http://rs.tdwg.org/dwc/terms/sex",
            :sex)
          add_meta(triples, h, "http://rs.tdwg.org/dwc/terms/lifeStage",
            :life_stage)
          add_meta(triples, h, "http://eol.org/schema/terms/statisticalMethod",
            :statistical_method)
          triples << "<#{h[:trait]}> dc:source <#{resource.graph_name}>"
          traits << h[:trait]
        end
      end
      paginate(associations_query(resource)) do |results|
        results.each do |h|
          triples << "<#{h[:page]}> a eol:page ;"\
            "<#{h[:predicate]}> <#{h[:target_page]}> ;"\
            "dc:source <#{resource.graph_name}>"
          triples << "<#{h[:target_page]}> a eol:page ;"\
            "<#{h[:inverse]}> <#{h[:page]}> ;"\
            "dc:source <#{resource.graph_name}>"
          traits << h[:trait]
        end
      end
      # Metadata is VERY SLOW! ...Have to do them ONE AT A TIME! :S
      EOL.log("Finding metadata for #{traits.count} traits...", prefix: ".")
      traits.each_with_index do |trait, index|
        EOL.log(index, prefix: ".") if index % 10_000 == 0
        begin
          EOL::Sparql.connection.query(metadata_query(resource, trait)).
            each do |h|
            # ?trait ?predicate ?meta_trait ?value ?units
            if h[:units].blank?
              add_meta(triples, h, h[:predicate], :value,
                literal: h[:value].literal?)
            else
              triples << "<#{h[:trait]}> <#{h[:predicate]}> <#{h[:meta_trait]}> ."
              val = h[:value].literal? ?
                "\"#{h[:value].to_s.gsub(/"/, "\\\"")}\"" :
                "<#{h[:value]}>"
              triples << "<#{h[:meta_trait]}> a eol:trait ;"\
                "<http://rs.tdwg.org/dwc/terms/measurementValue> #{val} ;"\
                "<http://rs.tdwg.org/dwc/terms/measurementUnit> <#{h[:units]}>"
            end
          end
        # This was causing a lot of trouble when I was attempting it:  :(
        rescue => e
          EOL.log("ERROR: #{e.message}")
          raise e
        end
      end
      # TODO: paginate the insert
      EOL::Sparql.connection.insert_data(data: triples, graph_name: graph_name)
      EOL.log_return
      taxa
    end

    def flatten_taxa(taxa)
      EOL.log_call
      EOL.log("Flattening #{taxa.count} taxa...", prefix: ".")
      taxa.to_a.in_groups_of(10_000, false) do |group|
        triples = []
        TaxonConceptsFlattened.where(taxon_concept_id: group).
          find_each do |flat|
          # Note the *ancestor* might not be a page yet: (often isn't!)
          triples << "<http://eol.org/pages/#{flat.ancestor_id}> a eol:page"
          triples << "<http://eol.org/pages/#{flat.taxon_concept_id}> "\
            "eol:has_ancestor <http://eol.org/pages/#{flat.ancestor_id}>"
        end
        EOL::Sparql.connection.insert_data(data: triples,
          graph_name: graph_name)
        EOL.log("Completed #{group.count}...", prefix: ".")
      end
    end

    def add_meta(triples, h, uri, key, options = {})
      return if h[key].nil?
      triple = "<#{h[:trait]}> <#{uri}> "
      if options[:literal]
        triple << "\"#{h[key].to_s.gsub(/"/, "\\\"")}\""
      else
        triple << "<#{h[key]}>"
      end
      triples << triple
    end

    def pages(limit = 1000, offset = nil)
      query = "SELECT DISTINCT *
      # pages
      WHERE {
        GRAPH <http://eol.org/traitbank> {
          ?page a eol:page
        }
      }
      LIMIT #{limit}
      #{"OFFSET #{offset}" if offset}"
      EOL::Sparql.connection.query(query).map do |r|
        r[:page].to_s.sub(/.*\/(\d+)$/, '\1')
      end
    end

    # NOTE (IMPORTANT!) - some versions of Virtuoso don't seem to paginate
    # correctly, and may skip some entries or produce duplicates. I'm not sure
    # why ours is different, but I did check it: pagination seems to work just
    # fine (without using an ORDER BY). [shrug] You should probably check!
    def paginate(query, options = {}, &block)
      EOL.log_call
      results = []
      limit = options[:limit] || default_limit
      limit = limit.to_i
      limit = default_limit if limit == 0
      offset = 0
      begin
        limited_query = query + " LIMIT #{limit}"
        limited_query += " OFFSET #{offset}" if offset > 0
        EOL.log(limited_query, prefix: "Q")
        results = EOL::Sparql.connection.query(limited_query)
        EOL.log("#{results.count} results", prefix: ".")
        yield(results) if results.count > 0
        offset += limit
      end until results.empty?
    end

    # Given a page, get all of its traits and all of its metadata. Note that
    # this necessarily returns a bunch of predicates of
    # <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, which you should
    # ignore. Sorry!
    def page_with_traits(page, limit = 10_000, offset = nil)
      query = "SELECT DISTINCT *
      # page_with_traits
      WHERE {
        GRAPH <http://eol.org/traitbank> {
          <http://eol.org/pages/#{page}> ?predicate ?trait .
          ?trait a eol:trait .
          ?trait ?trait_predicate ?value .
          OPTIONAL { ?value a eol:trait . ?value ?meta_predicate ?meta_value }
        }
      }
      LIMIT #{limit}
      #{"OFFSET #{offset}" if offset}"
      EOL::Sparql.connection.query(query)
    end

    # e.g.: http://purl.obolibrary.org/obo/OBA_1000036 on http://eol.org/pages/41
    def data_search(predicate, limit = 10_000, offset = nil)
      query = "SELECT DISTINCT *
      # data_search
      WHERE {
        GRAPH <http://eol.org/traitbank> {
          ?page <#{predicate}> ?trait .
          ?trait a eol:trait .
          ?trait ?trait_predicate ?value .
          OPTIONAL { ?value a eol:trait . ?value ?meta_predicate ?meta_value }
        }
      }
      LIMIT #{limit}
      #{"OFFSET #{offset}" if offset}"
      EOL::Sparql.connection.query(query)
    end

    # NOTE: I copy/pasted this. TODO: generalize. For testing, 37 should include
    # 41, and NOT include 904.
    def data_search_within_clade(predicate, clade, limit = 10_000, offset = nil)
      query = "SELECT DISTINCT *
      # data_search_within_clade
      WHERE {
        GRAPH <http://eol.org/traitbank> {
          ?page <#{predicate}> ?trait .
          ?page eol:has_ancestor <http://eol.org/pages/#{clade}> .
          ?trait a eol:trait .
          ?trait ?trait_predicate ?value .
          OPTIONAL { ?value a eol:trait . ?value ?meta_predicate ?meta_value }
        }
      }
      LIMIT #{limit}
      #{"OFFSET #{offset}" if offset}"
      EOL::Sparql.connection.query(query)
    end

    # Given a list of traits, get all the metadata for them:
    def get_traits(traits, limit = 10_000, offset = nil)
      query = "SELECT DISTINCT *
      # get_traits
      WHERE {
        GRAPH <http://eol.org/traitbank> {
          ?trait ?predicate ?value .
          ?trait a eol:trait .
          OPTIONAL { ?value a eol:trait . ?value ?meta_predicate ?meta_value }
          FILTER (?trait IN (<#{traits.map(&:to_s).join('>,<')}>))
        }
      }
      LIMIT #{limit}
      #{"OFFSET #{offset}" if offset}"
      EOL::Sparql.connection.query(query)
    end

    def measurements_query(resource)
      "SELECT DISTINCT *
        # measurements_query
        WHERE {
          GRAPH <#{resource.graph_name}> {
            ?trait dwc:measurementType ?predicate .
            ?trait dwc:measurementValue ?value .
            OPTIONAL { ?trait dwc:measurementUnit ?units } .
            OPTIONAL { ?trait eolterms:statisticalMethod ?statistical_method } .
          } .
          {
            ?trait dwc:taxonConceptID ?page .
            OPTIONAL { ?trait dwc:lifeStage ?life_stage } .
            OPTIONAL { ?trait dwc:sex ?sex }
          }
          UNION {
            ?trait dwc:occurrenceID ?occurrence .
            ?occurrence dwc:taxonID ?taxon .
            ?trait eol:measurementOfTaxon eolterms:true .
            GRAPH <#{resource.mappings_graph_name}> {
              ?taxon dwc:taxonConceptID ?page
            }
            OPTIONAL { ?occurrence dwc:lifeStage ?life_stage } .
            OPTIONAL { ?occurrence dwc:sex ?sex }
          }
        }"
    end

    # TODO: http://eol.org/known_uris should probably be a function somewhere.
    def associations_query(resource)
      "SELECT DISTINCT *
        # associations_query
        WHERE {
          GRAPH <#{resource.mappings_graph_name}> {
            ?taxon dwc:taxonConceptID ?page .
            ?value dwc:taxonConceptID ?target_page
          } .
          GRAPH <#{resource.graph_name}> {
            ?occurrence dwc:taxonID ?taxon .
            ?target_occurrence dwc:taxonID ?value .
            {
              ?trait dwc:occurrenceID ?occurrence .
              ?trait eol:targetOccurrenceID ?target_occurrence .
              ?trait eol:associationType ?predicate
            }
            UNION
            {
              ?trait dwc:occurrenceID ?target_occurrence .
              ?trait eol:targetOccurrenceID ?occurrence .
              ?trait eol:associationType ?inverse
            }
          } .
          OPTIONAL {
            GRAPH <http://eol.org/known_uris> {
              ?inverse owl:inverseOf ?predicate
            }
          }
        }"
    end

    def metadata_query(resource, trait)
      "SELECT DISTINCT *
      # metadata_query
      WHERE {
        GRAPH <#{resource.graph_name}> {
          {
            ?trait ?predicate ?value .
          } UNION {
            ?trait dwc:occurrenceID ?occurrence .
            ?occurrence ?predicate ?value .
          } UNION {
            ?meta_trait eol:parentMeasurementID ?trait .
            ?meta_trait dwc:measurementType ?predicate .
            ?meta_trait dwc:measurementValue ?value .
            OPTIONAL { ?meta_trait dwc:measurementUnit ?units } .
          } UNION {
            ?trait dwc:occurrenceID ?occurrence .
            ?meta_trait dwc:occurrenceID ?occurrence .
            ?meta_trait dwc:measurementType ?predicate .
            ?meta_trait dwc:measurementValue ?value .
            FILTER NOT EXISTS { ?meta_trait eol:measurementOfTaxon eolterms:true } .
            OPTIONAL { ?meta_trait dwc:measurementUnit ?units } .
          } UNION {
            ?meta_trait eol:associationID ?trait .
            ?meta_trait dwc:measurementType ?predicate .
            ?meta_trait dwc:measurementValue ?value .
            OPTIONAL { ?meta_trait dwc:measurementUnit ?units } .
          } UNION {
            ?trait dwc:occurrenceID ?occurrence .
            ?occurrence dwc:eventID ?event .
            ?event ?predicate ?value .
          } UNION {
            ?trait dwc:occurrenceID ?occurrence .
            ?occurrence dwc:taxonID ?taxon .
            ?taxon ?predicate ?value .
            FILTER (?predicate = dwc:scientificName)
          }
          FILTER (?predicate NOT IN (rdf:type, dwc:taxonConceptID, dwc:measurementType, dwc:measurementValue,
                                     dwc:measurementID, eolreference:referenceID,
                                     eol:targetOccurrenceID, dwc:taxonID, dwc:eventID,
                                     eol:associationType,
                                     dwc:measurementUnit, dwc:occurrenceID, eol:measurementOfTaxon)
                  ) .
          FILTER (?trait  = <#{trait}>)
        }
      }"
    end
  end
end
