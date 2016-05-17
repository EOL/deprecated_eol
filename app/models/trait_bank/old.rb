class TraitBank::Old
  class << self
    def connection
      @conneciton ||= EOL::Sparql.connection
    end

    # NOTE: this is only used for debugging. It shows "old TB" measurements (not
    # associations) for a given page, optionally from a given resource.
    def measurements(options = {})
      limit = options[:limit] || 1000
      connection.query(measurements_query(options) + " LIMIT #{limit}")
    end

    def associations(options = {})
      limit = options[:limit] || 1000
      connection.query(associations_query(options) + " LIMIT #{limit}")
    end

    # NOTE: Cannot filter by page, only resource. Careful!
    def references(options = {})
      limit = options[:limit] || 1000
      connection.query(references_query(options) + " LIMIT #{limit}")
    end

    def paginate_measurements(options, &block)
      TraitBank.paginate(measurements_query(options)) { |res| yield(res) }
    end

    def paginate_associations(options, &block)
      TraitBank.paginate(associations_query(options)) { |res| yield(res) }
    end

    # NOTE: Cannot filter by page, only resource. Careful!
    def paginate_references(options, &block)
      TraitBank.paginate(references_query(options)) { |res| yield(res) }
    end

    def query_with_options(query, options = {})
      page = "?page"
      if options[:page]
        page_id = options[:page].respond_to?(:id) ?
          options[:page].id : options[:page]
        page = "<http://eol.org/pages/#{page_id}>"
      end
      res_graph = "?graph"
      map_graph = "?map_graph"
      if options[:resource]
        res_graph = "<#{options[:resource].graph_name}>"
        map_graph = "<#{options[:resource].mappings_graph_name}>"
      end
      query.sub('_RES_GRAPH_', res_graph).
            sub('_MAP_GRAPH_', map_graph).
            sub('_PAGE_', page)
    end

    # NOTE: this used to have a UNION, but I discovered there was exactly ONE
    # trait in all of TB that actually matched it (and I guess it was old, ID
    # was 1), so I removed it.
    def measurements_query(options = {})
      query_with_options("SELECT DISTINCT *
        # measurements_query
        WHERE {
          GRAPH _RES_GRAPH_ {
            ?trait dwc:measurementType ?predicate .
            ?trait dwc:measurementValue ?value .
            OPTIONAL { ?trait dwc:measurementUnit ?units } .
            OPTIONAL { ?trait eolterms:statisticalMethod ?statistical_method } .
          } .
          {
            ?trait dwc:occurrenceID ?occurrence .
            ?occurrence dwc:taxonID ?taxon .
            ?trait eol:measurementOfTaxon eolterms:true .
            GRAPH _MAP_GRAPH_ {
              ?taxon dwc:taxonConceptID _PAGE_
            }
            OPTIONAL { ?occurrence dwc:lifeStage ?life_stage } .
            OPTIONAL { ?occurrence dwc:sex ?sex }
          }
        }", options)
    end

    # TODO: http://eol.org/known_uris should probably be a function somewhere.
    def associations_query(options = {})
      query_with_options("SELECT DISTINCT *
        # associations_query
        WHERE {
          GRAPH _MAP_GRAPH_ {
            ?taxon dwc:taxonConceptID _PAGE_ .
            ?value dwc:taxonConceptID ?target_page
          } .
          GRAPH _RES_GRAPH_ {
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
        }", options)
    end

    # OLD: ?parent_uri ?identifier ?publicationType ?full_reference ?primaryTitle
    # ?title ?pages ?pageStart ?pageEnd ?volume ?edition ?publisher ?authorList
    # ?editorList ?created ?language ?uri ?doi ?localityName
    # NOTE: This can't be filtered by page, only by resource. Be careful!
    def references_query(options = {})
      # {optional_reference_uris} removed because it never showed up on the old
      # version of TB, and it's largely redundant. NOTE that storing
      # full_reference everywhere it's used is quite redundant, but it's much,
      # much easier to render, so I'm ignoring that.
      query_with_options("SELECT DISTINCT *
       #references_query
        WHERE {
          GRAPH _RES_GRAPH_ {
            {
              ?trait eolreference:referenceID ?reference .
              ?reference a eolreference:Reference .
              ?reference <#{TraitBank.full_reference_uri}> ?full_reference
            }
          }
        }", options)
    end

    def metadata_in_bulk(resource, traits)
      unions = [
        "?trait ?predicate ?value .",
        "?trait dwc:occurrenceID ?occurrence . ?occurrence ?predicate ?value .",
        "?meta_trait eol:parentMeasurementID ?trait . "\
          "?meta_trait dwc:measurementType ?predicate . "\
          "?meta_trait dwc:measurementValue ?value . "\
          "OPTIONAL { ?meta_trait dwc:measurementUnit ?units } .",
        # I'm killing this, as it seems to make everything dreadfully slow. My
        # alternative is not technically accurate, but it'll do in a pinch.
        # "FILTER NOT EXISTS { ?meta_trait eol:measurementOfTaxon eolterms:true } . "\
        # ...replaced with "?meta_trait eol:measurementOfTaxon eolterms:false . "
        "?trait dwc:occurrenceID ?occurrence . "\
          "?meta_trait dwc:occurrenceID ?occurrence . "\
          "?meta_trait dwc:measurementType ?predicate . "\
          "?meta_trait dwc:measurementValue ?value . "\
          "?meta_trait eol:measurementOfTaxon eolterms:false . "\
          "OPTIONAL { ?meta_trait dwc:measurementUnit ?units } .",
        "?meta_trait eol:associationID ?trait . "\
          "?meta_trait dwc:measurementType ?predicate . "\
          "?meta_trait dwc:measurementValue ?value . "\
          "OPTIONAL { ?meta_trait dwc:measurementUnit ?units } .",
        "?trait dwc:occurrenceID ?occurrence . "\
          "?occurrence dwc:eventID ?event . "\
          "?event ?predicate ?value .",
        "?trait dwc:occurrenceID ?occurrence . "\
          "?occurrence dwc:taxonID ?taxon . "\
          "?taxon ?predicate ?value . "\
          "FILTER (?predicate = dwc:scientificName)"
      ]
      results = []
      unions.each do |subquery|
        results += begin
          connection.query(metadata_bulk_query(resource, subquery, traits))
        rescue EOL::Exceptions::SparqlDataEmpty => e
          []
        rescue => e
          EOL.log("WARNING metadata may be missing: #{e}", prefix: "!")
          []
        end
      end
      results
    end

    def metadata_bulk_query(resource, subquery, traits)
      "SELECT DISTINCT * "\
        "WHERE { GRAPH <#{resource.graph_name}> { "\
        "  { #{subquery} } #{metadata_predicate_filter} "\
        "  FILTER (?trait IN (<#{traits.join(">,<")}>)) } } "\
        "# metadata_bulk_query "
    end

    def metadata_predicate_filter
      "FILTER (?predicate NOT IN (rdf:type, dwc:taxonConceptID, "\
        "dwc:measurementType, dwc:measurementValue, dwc:measurementID, "\
        "eolreference:referenceID, eol:targetOccurrenceID, dwc:taxonID, "\
        "dwc:eventID, eol:associationType, dwc:measurementUnit, "\
        "dwc:occurrenceID, eol:measurementOfTaxon)) ."
    end

    def optional_reference_uris
      return @optional_reference_uris if @optional_reference_uris
      @optional_reference_uris = []
      Rails.configuration.optional_reference_uris.each do |var, url|
        @optional_reference_uris << "OPTIONAL { ?reference <#{url}> ?#{var} } ."
      end
      return "" if @optional_reference_uris.empty?
      @optional_reference_uris.join(" ")
    end

    # NOTE: unused; for debugging only:
    def triples_count_from_resource(resource)
      TraitBank.connection.query(
          "SELECT COUNT(*) { "\
            "GRAPH <#{resource.graph_name}> { ?s ?p ?o } } LIMIT 1"
        ).first[:"callret-0"].to_i
    end

    # NOTE: unused; for debugging only:
    def measurements_count_from_resource(resource)
      TraitBank.connection.query(
        "SELECT COUNT(*) { GRAPH <#{resource.graph_name}> { ?s "\
          "<http://eol.org/schema/measurementOfTaxon> "\
          "<http://eol.org/schema/terms/true> } }"
        ).first[:"callret-0"].to_i
    end

    # NOTE: unused; for debugging only:
    def predicates_from_resource(resource)
      TraitBank.connection.query("SELECT distinct(?p) { "\
        "GRAPH <#{resource.graph_name}> { ?s ?p ?o } }").map { |t| t[:p].to_s }
    end
  end
end
