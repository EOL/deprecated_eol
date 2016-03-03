class TraitBank
  class << self
    attr_reader :default_limit, :graph, :taxon_re
  end

  SOURCE_RE = /http:\/\/eol.org\/resources\/(\d+)$/

  @default_limit = 5000
  @taxon_re = Rails.configuration.known_taxon_uri_re
  @graph = "http://eol.org/traitbank"

  class << self
    def cache_query(key, &block)
      result = Rails.cache.fetch(key, expires_in: 1.day) do
        begin
          yield
        rescue EOL::Exceptions::SparqlDataEmpty => e
          []
        end
      end
      if result.nil? || result.blank?
        # Don't store empty results:
        Rails.cache.delete(key)
        EOL.log("TB.cache_query: #{key} (0 results, not saved)")
      elsif result.respond_to?(:count)
        EOL.log("TB.cache_query: #{key} (#{result.count} results)")
      elsif result.is_a?(Fixnum) || result.is_a?(String)
        EOL.log("TB.cache_query: #{key} (#{result})")
      else
        EOL.log("TB.cache_query: uncountable result, sorry.")
      end
      result
    end

    def connection
      @conneciton ||= EOL::Sparql.connection
    end

    # Stupid that this is hidden as much as it is:
    def prefixes
      connection.send :namespaces_prefixes
    end

    def uri?(uri)
      EOL::Sparql.is_uri?(uri)
    end

    def delete_resource(resource)
      paginate(resource_predicates_query(resource), limit: 1000) do |results|
        delete(results.map { |r| "<#{r[:p]}> ?s ?o" })
      end
    end

    def resource_predicates_query(resource)
      "SELECT DISTINCT(?p) { GRAPH <#{graph}> "\
      "{ ?p dc:source <#{resource.graph_name}> } }"
    end

    # NOTE that this is stupid syntax, but it's what you have to do with Sparql.
    # Yes, it looks very redundant! NOTE: limit must be restricted as the SQL
    # query can get too long. Sigh.
    def delete(triples)
      triple_string = triples.join(" .\n")
      query = "WITH GRAPH <#{graph}> DELETE { #{triples} } "\
        "WHERE { #{triples} }"
      begin
        connection.query(query)
      rescue EOL::Exceptions::SparqlDataEmpty => e
        # Do nothing... this is acceptable for a delete...
      end
    end

    def quote_literal(literal)
      str = begin
        literal.to_s
      rescue
        raise "Can't convert #{literal.class} into a string: #{literal.inspect}"
      end
      if str.is_numeric?
        str
      else
        "\"#{str.gsub(/\n/, " ").gsub(/"/, "\\\"")}\""
      end
    end

    def exists?(uri)
      r = connection.query("SELECT COUNT(*) { <#{uri}> ?o ?p }")
      return false unless r.first && r.first.has_key?(:"callret-0")
      r.first[:"callret-0"].to_i > 0
    end

    # Returns an Set (not an array!) of which uris DO exist.
    def group_exists?(uris)
      exist = Set.new
      uris.to_a.in_groups_of(1000, false) do |group|
        begin
          resp = connection.query("SELECT DISTINCT(?s) { ?s ?o ?p } "\
            "FILTER ( ?s IN (<#{uris.join(">,<")}>) )")
          exist += resp.map { |u| u[:s].to_s }
        rescue EOL::Exceptions::SparqlDataEmpty => e
          # Nothing to add.
        end
      end
      exist
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
      # connection.query("CLEAR GRAPH <#{graph}>")
      taxa = Set.new
      begin
        Resource.where("harvested_at IS NOT NULL").find_each do |resource|
          count = resource.trait_count
          EOL.log("Rebuild resource? #{resource.title} (#{resource.id}): #{count}")
          # Rebuild this one if there are any triples in the (old) graph:
          taxa += TraitBank::ResourcePorter.port(resource) if count > 0
        end
      rescue => e
        EOL.log("FAILED! Will still flatten available taxa...", prefix: "!")
        raise e
      ensure
        if taxa.count > 0
          # This could be QUITE a lot... many millions. :\
          flatten_taxa(taxa)
        else
          EOL.log("No taxa detected; nothing flattened.", prefix: ".")
        end
      end
      EOL.log_return
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
        connection.insert_data(data: triples,
          graph_name: graph)
        EOL.log("Completed #{group.count}...", prefix: ".")
      end
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
      connection.query(query).map do |r|
        r[:page].to_s.sub(/.*\/(\d+)$/, '\1')
      end
    end

    # NOTE (IMPORTANT!) - some versions of Virtuoso don't seem to paginate
    # correctly, and may skip some entries or produce duplicates. I'm not sure
    # why ours is different, but I did check it: pagination seems to work just
    # fine (without using an ORDER BY). [shrug] You should probably check!
    def paginate(query, options = {}, &block)
      put_query = false
      results = []
      limit = options[:limit] || default_limit
      limit = limit.to_i
      limit = default_limit if limit == 0
      offset = 0
      begin
        limited_query = query + " LIMIT #{limit}"
        limited_query += " OFFSET #{offset}" if offset > 0
        results = connection.query(limited_query)
        if results && results.count > 0
          unless put_query
            EOL.log("#{query[0..110].gsub(/\s+/m, " ")}...", prefix: "Q")
            put_query = true
          end
          EOL.log("#{offset + results.count}", prefix: ".")
          yield(results)
        end
        offset += limit
      end until results.empty?
    end

    def clear_predicates
      Rails.cache.delete(predicates_cache_name)
    end

    def predicates
      Rails.cache.fetch(predicates_cache_name, expires_in: 1.week) do
        predicates_rows
      end
    end

    def predicates_cache_name
      "trait_bank/predicates"
    end

    # Returns an array of [id (a string), uri, name] arrays
    def predicates_rows
      EOL.pluck_fields([:known_uri_id, :uri, :name],
        TranslatedKnownUri.joins(:known_uri).
          where(language_id: Language.english.id,
            known_uris: { uri: predicates_uris}).
          where("name IS NOT NULL AND name != ''").order("name")).
        map do |string|
        string.split(',', 3)
      end

    end

    def predicates_uris
      predicates_rdf.map { |rdf| rdf[:predicate].to_s }
    end

    # NOTE: this takes a LONG, long time. Over a minute. You have been warned.
    def predicates_rdf
      query = "PREFIX eol: <http://eol.org/schema/> select "\
        "DISTINCT(?predicate) { graph <http://eol.org/traitbank> "\
        "{ ?page ?predicate ?trait . ?trait a eol:trait . ?page a eol:page } }"
      connection.query(query)
    end

    # Given a page, get all of its traits and all of its metadata. Note that
    # this necessarily returns a bunch of predicates of
    # <http://www.w3.org/1999/02/22-rdf-syntax-ns#type>, which you should
    # ignore. Sorry! NOTE: duplication with #page_traits
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
      begin
        connection.query(query)
      rescue EOL::Exceptions::SparqlDataEmpty => e
        EOL.log_error(e)
        []
      end
    end

    # JUST the list of triat IDs for the page! NOTE: duplication with
    # #page_with_traits
    def page_traits(page, limit = 10_000, offset = nil)
      query = "SELECT DISTINCT *
      # page_with_traits
      WHERE {
        GRAPH <http://eol.org/traitbank> {
          <http://eol.org/pages/#{page}> ?predicate ?trait
        }
      }"
      begin
        connection.query(query)
      rescue EOL::Exceptions::SparqlDataEmpty => e
        EOL.log_error(e)
        []
      end
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
      connection.query(query)
    end

    def measurements_query(resource)
      "SELECT DISTINCT *
        # measurements_query
        WHERE {
          GRAPH <#{resource.graph}> {
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

    # NOTE: I tried to have this take multiple traits and use an IN. ...it works
    # fine... MOST of the time. But there are SPECIFIC URIs that cause the time
    # estimate to go through the roof (e.g., if
    # <http://eol.org/resources/737/measurements/a62006f2ac1305d8b4eb9482cf3f6776>
    # is IN THE SET, the whole query fails because it thinks it will take too
    # long). I don't have time to figure out why, so we CRAWL through these one
    # at a time. Sigh.
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
          FILTER (?trait = <#{trait}>)
        }
      }"
    end
  end
end
