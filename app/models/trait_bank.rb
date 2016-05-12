class TraitBank
  class << self
    attr_reader :default_limit, :graph, :taxon_re, :value_uri, :unit_uri,
      :type_uri, :source_uri, :resource_uri, :sex_uri, :life_stage_uri,
      :statistical_method_uri, :full_reference_uri, :association_uri,
      :inverse_uri, :object_page_uri, :subject_page_uri, :iucn_uri
  end

  SOURCE_RE = /http:\/\/eol.org\/resources\/(\d+)$/
  PAGE_RE = /http:\/\/eol.org\/pages\/(\d+)$/

  @default_limit = 5000
  @taxon_re = Rails.configuration.known_taxon_uri_re
  @association_uri = "http://eol.org/schema/associationType"
  @inverse_uri = "http://eol.org/schema/inverseAssociationType"
  @object_page_uri = "http://eol.org/schema/objectPage"
  @subject_page_uri = "http://eol.org/schema/subjectPage"
  @value_uri = "http://rs.tdwg.org/dwc/terms/measurementValue"
  @unit_uri = "http://rs.tdwg.org/dwc/terms/measurementUnit"
  @type_uri = "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
  @source_uri = "http://purl.org/dc/terms/source"
  @iucn_uri = "http://rs.tdwg.org/ontology/voc/SPMInfoItems#ConservationStatus"
  @resource_uri = "http://eol.org/schema/terms/resource"
  @sex_uri = "http://rs.tdwg.org/dwc/terms/sex"
  @life_stage_uri = "http://rs.tdwg.org/dwc/terms/lifeStage"
  @statistical_method_uri = "http://eol.org/schema/terms/statisticalMethod"
  @full_reference_uri = "http://eol.org/schema/reference/full_reference"
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
      elsif result.is_a?(String)
        EOL.log("TB.cache_query: #{key} (#{result[0..29]})")
      elsif result.is_a?(Fixnum)
        EOL.log("TB.cache_query: #{key} (#{result})")
      elsif result.respond_to?(:size)
        EOL.log("TB.cache_query: #{key} (#{result.size} results)")
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

    # Even 100 is too many for this paginate... throws a "generated SQL too
    # long" error. Sigh.
    def delete_resource(resource)
      paginate(resource_predicates_query(resource), limit: 50) do |results|
        delete(results.map { |r| "<#{r[:s]}> ?s ?o" })
      end
    end

    def resource_predicates_query(resource)
      "SELECT DISTINCT(?s) { GRAPH <#{graph}> "\
      "{ ?s <#{TraitBank.resource_uri}> <#{resource.graph_name}> } }"
    end

    # NOTE that this is stupid syntax, but it's what you have to do with Sparql.
    # Yes, it looks very redundant! NOTE: limit must be restricted as the SQL
    # query can get too long. Sigh. NOTE: ARGH! Doesn't work reliably in batches; must be done one at a time to work...
    def delete(triples)
      # triple_string = triples.join(" . ")
      triples.each do |triple_string|
        query = "WITH GRAPH <#{graph}> DELETE { #{triple_string} } "\
          "WHERE { #{triple_string} }"
        begin
          connection.query(query)
        rescue EOL::Exceptions::SparqlDataEmpty => e
          # Do nothing... this is acceptable for a delete...
        end
      end
    end

    def quote_literal(literal)
      str = begin
        literal.to_s
      rescue
        raise "Can't convert #{literal.class} into a string: #{literal.inspect}"
      end
      if str.is_numeric?
        str.sub(/^\+/, '')
      else
        "\"#{str.gsub(/\n/, " ").gsub(/\\/, "\\\\\\\\").gsub(/"/, "\\\"")}\""
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
          resp = connection.query("SELECT DISTINCT(?s) { ?s ?o ?p . "\
            "FILTER ( ?s IN (<#{uris.join(">,<")}>) ) }")
          exist += resp.map { |u| u[:s].to_s }
        rescue EOL::Exceptions::SparqlDataEmpty => e
          # Nothing to add.
        end
      end
      exist
    end

    def rebuild
      EOL.log_call
      EOL.log("Prefixes, for convenience:", prefix: ".")
      EOL.log(prefixes, prefix: ".")
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

    def create_mappings(resource)
      triples = []
      graph = resource.graph_name
      resource.hierarchy.entries.select([:id, :identifier, :taxon_concept_id]).
               find_each do |entry|
        entry_uri = "#{graph}/taxa/#{EOL::Sparql.to_underscore(entry.identifier)}"
        page_uri = "http://eol.org/pages/#{entry.taxon_concept_id}"
        triples << "<#{entry_uri}> dwc:taxonConceptID <#{page_uri}>"
      end
      map_graph = resource.mappings_graph_name
      EOL::Sparql.delete_graph(map_graph)
      connection.insert_data(data: triples, graph_name: map_graph)
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
        connection.insert_data(data: triples, graph_name: graph)
        EOL.log("Completed #{group.count}...", prefix: ".")
      end
    end

    def pages(limit = 1000, offset = nil)
      query = "SELECT DISTINCT *
      # pages
      WHERE {
        GRAPH <#{TraitBank.graph}> {
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
          count = offset + results.count
          EOL.log("paginating for more results: #{count}", prefix: ".") if
            count % 10_000
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
        "DISTINCT(?predicate) { graph <#{TraitBank.graph}> "\
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
        GRAPH <#{TraitBank.graph}> {
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
        GRAPH <#{TraitBank.graph}> {
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
        GRAPH <#{TraitBank.graph}> {
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

    def iucn_data(page_id)
      TraitBank.cache_query("trait_bank/iucn_data/#{page_id}") do
        query = "SELECT DISTINCT * WHERE { GRAPH <#{TraitBank.graph}> {"\
        " <http://eol.org/pages/#{page_id}> <#{TraitBank.iucn_uri}> ?trait ."\
        " ?trait <#{TraitBank.value_uri}> ?value . "\
        " ?trait <#{TraitBank.source_uri}> ?source "\
        "} } # iucn_status query"
        result = connection.query(query)
        return nil if result.empty?
        hash = { status: result.first[:value].to_s }
        source_row = result.find { |r| r[:source] !~ TraitBank::SOURCE_RE }
        hash[:source] = source_row[:source].to_s if source_row
        hash
      end
    end
  end
end
