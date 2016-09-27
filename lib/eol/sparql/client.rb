module EOL
  module Sparql
    class Client

      attr_accessor :endpoint_uri, :namespaces, :username, :password, :sparql_client
      extend EOL::Sparql::SafeConnection # Note we ONLY need the class methods, so #extend
      extend EOL::LocalCacheable

      def self.clear_uri_caches
        Rails.cache.delete(cache_key("all_measurement_type_uris"))
        Rails.cache.delete("known_uris/measurements/show_in_gui/uris")
        Rails.cache.delete(cache_key("all_measurement_type_known_uris"))
        id = 1
        while tcid = Rails.cache.read(cache_key("cached_taxon_#{id}")) do
          Rails.cache.delete(clade_cache_key(tcid))
          Rails.cache.delete(cache_key("cached_taxon_#{id}"))
          id += 1
        end
      end

      # NOTE: Don't use slashes; these must also be valid variable names because
      # of the way that we store them "locally". Stupid, but there you have it.
      def self.cache_key(name)
        "eol_sparql_client_#{name}"
      end

      def self.clade_cache_key(id)
        cache_key("all_measurement_type_known_uris_for_clade_#{id}")
      end

      def initialize(options = {})
        @endpoint_uri = options[:endpoint_uri]
        @username = options[:username]
        @password = options[:password]
        @namespaces = EOL::Sparql::NAMESPACES
        @sparql_client = SPARQL::Client.new(endpoint_uri)
      end

      # NOTE: "callret-0" is the name of the symbol returned by a COUNT query.
      # NOTE we aren't counting triples, we are counting the number of taxonIDs
      # referenced, because both measurements and associations use this to mark
      # the association between an "occurrence" and a "taxon" (which is really a
      # hierarchy_entry.identifier)
      def count_traits_in_resource(resource)
        query("SELECT COUNT(*) WHERE { GRAPH "\
          "<#{resource.graph_name}> { ?s dwc:taxonID ?o } }").
          first[:"callret-0"].to_i
      end

      def traits_in_resource(resource)
        EOL.log_call
        traits = Set.new
        these = []
        offset = 0
        batch = 10_000
        begin
          EOL.log("#{offset}", prefix: ".")
          these = query("SELECT ?s WHERE { GRAPH "\
            "<#{resource.graph_name}> { ?s dwc:taxonID ?o } } "\
            "LIMIT #{batch} OFFSET #{offset}")
          traits += these.map { |t| t[:s].to_s }
          offset += batch
        end until these.empty?
        traits.to_a
      end

      # In Dec 2015 it became clear that harvesting was adding triples for taxa
      # and references, even when there is NO DATA in the resource. This will
      # help us find those, and, if we decide it's safe, drop the graphs.
      # ...It's possible that it's required for searches, though, so not doing
      # that now.
      def count_triples_in_resource(resource)
        sparql_client.query("SELECT COUNT(*) WHERE { GRAPH "\
          "<#{resource.graph_name}> { ?s ?p ?o } }").first[:"callret-0"].to_i
      end

      # You must implement this in your child class.
      def insert_data(options={})
        raise NotImplementedError
      end

      def delete_data(options = {})
        if options[:graph_name] && options[:data]
          update("DELETE DATA FROM <#{options[:graph_name]}> { #{options[:data]} }")
        end
      end

      def delete_uri(options)
        if options[:graph_name] && options[:uri]
          sparql_client.query("DELETE FROM <#{options[:graph_name]}> { <#{options[:uri]}> ?p ?o } WHERE { <#{options[:uri]}> ?p ?o }")
        end
      end

      def update(query)
        sparql_client.query("#{namespaces_prefixes} #{query}")
      end

      def delete_graph(graph_name)
        return unless graph_name
        delete_graph_via_sparql_update(graph_name)
      end

      def query(query, options = {})
        results = []
        return results unless EolConfig.data?
        begin
          if Rails.configuration.respond_to?('show_sparql_queries') && Rails.configuration.show_sparql_queries
            EOL.log("#{options[:prefix]}\n#{namespaces_prefixes}\n#{query}")
          end
          sparql_client.query("#{options[:prefix]} #{namespaces_prefixes} #{query}").each_solution { |s| results << s.to_hash }
        rescue => e
          EOL.log("ERROR: Virtuoso Connection refused: #{e.message}", prefix: "!")
          EOL.log("Query: \"#{options[:prefix]}\n#{namespaces_prefixes}\n#{query}\"",
            prefix: "!")
          raise EOL::Exceptions::SparqlDataEmpty # This gets caught by our code gracefully.
        rescue ArgumentError => e
          # NOTE - this catch is caused by going through the demo for setting up the DAV user/directory. You've got to manually delete that
          # later!
          if e.message =~ /Invalid port number/
            EOL.log("We found a graph that cannot be removed programmatically.")
            EOL.log("Please go to http://localhost:8890/ => Conductor => LinkedData => Graphs and check to see")
            EOL.log("if there is a graph named http://localhost:8890%2FDAV%2Fxx%2Fyy ...if so, delete it and")
            EOL.log("try again. Sorry!")
          end
          raise e
        end
        results
      end

      def unknown_measurement_unit_uris
        unknown_uris_from_array(counts_of_all_measurement_unit_uris)
      end

      def unknown_measurement_type_uris
        unknown_uris_from_array(counts_of_all_measurement_type_uris)
      end

      def unknown_measurement_value_uris
        unknown_uris_from_array(counts_of_all_measurement_value_uris)
      end

      def unknown_association_type_uris
        unknown_uris_from_array(counts_of_all_association_type_uris)
      end

      def all_measurement_type_uris
        # NOTE: THIS STILL TAKE A LOOOOONG TIME TO RUN... about a minute! :S
        return Rails.cache.fetch("known_uris/measurements/show_in_gui/uris",
          expires_in: 2.weeks) do
          EOL::Sparql::Client.if_connection_fails_return([]) do
            result = query("
              SELECT DISTINCT ?uri WHERE {
                ?measurement dwc:measurementType ?uri .
                ?measurement eol:measurementOfTaxon eolterms:true .
                FILTER (isURI(?uri))
              }")
            result.map { |r| r[:uri].to_s }
          end
        end

        # TODO: re-write this, the query always times out and is overloading the system.
        # self.class.cache_fetch_with_local_timeout(
        #   self.class.cache_key("all_measurement_type_uris"), :expires_in => 2.weeks) do
        #   counts_of_all_measurement_type_uris.map { |k,v| k }
        # end
      end

      def all_measurement_type_known_uris
        uris = self.class.cache_fetch_with_local_timeout(
          self.class.cache_key("all_measurement_type_known_uris"), :expires_in => 2.weeks) do
            all_uris = all_measurement_type_uris
            all_known_uris = KnownUri.by_uris(all_uris)
            all_uris.map { |uri| all_known_uris.detect { |kn| kn.uri == uri } }
        end
        # If that list is empty, it indicates that Virtuoso is broken. Don't
        # cache this (or any) value, otherwise it will be blank for 24 hours!
        self.class.clear_uri_caches if uris.blank?
        uris
      end

      # NOTE: we do NOT clear the cache here, if it's empty, just in case it
      # really IS empty FOR THIS CLADE... we don't want all caches cleared, in
      # that case! We'll rely on #all_measurement_type_known_uris to clear the
      # caches if things are broken--it should be called often enough.
      def all_measurement_type_known_uris_for_clade(taxon_concept)
        remember_cached_taxon(taxon_concept.id)
        self.class.cache_fetch_with_local_timeout(
          self.class.clade_cache_key(taxon_concept.id),
          :expires_in => 2.weeks) do
          all_uris = counts_of_all_measurement_type_uris_in_clade(taxon_concept).map { |k,v| k }
          all_known_uris = KnownUri.by_uris(all_uris)
          all_uris.map { |uri| all_known_uris.detect { |kn| kn.uri == uri } }
        end
      end

      # This implements a VERY CRUDE queuing mechaism to avoid collisions.
      # Better than nothing, but only hardly so.
      def remember_cached_taxon(tcid)
        count = 1
        until Rails.cache.write(
          self.class.cache_key("cached_taxon_#{count}"), tcid, unless_exist: true
        ) do
          count += 1
        end
      end

      # Takes #counts_of_all_value_uris_by_type and replaces the URI key with a KnownUri:
      def counts_of_all_value_known_uris_by_type
        self.class.cache_fetch_with_local_timeout(
          self.class.cache_key("counts_of_all_value_known_uris_by_type"),
          :expires_in => 2.weeks) do
            counts = counts_of_all_value_uris_by_type
            Hash[
              KnownUri.by_uris(counts.keys.compact).map do |kuri|
                [ kuri, counts[kuri.uri] ]
              end
            ]
        end
      end

    private

      def delete_graph_via_sparql_update(graph_name)
        return unless graph_name
        update("CLEAR GRAPH <#{graph_name}>")
        update("DROP SILENT GRAPH <#{graph_name}>")
      end

      def namespaces_prefixes
        namespaces.map { |key,value| "PREFIX #{key}: <#{value}>"}.join(" ")
      end

      def unknown_uris_from_array(uris_with_counts)
        unknown_uris_with_counts = uris_with_counts
        known_uris = KnownUri.by_uris(unknown_uris_with_counts.keys)
        known_uris.each do |known_uri|
          unknown_uris_with_counts.delete_if { |uri, count| known_uri.matches(uri) }
        end
        unknown_uris_with_counts
      end

      def group_counts_by_uri(result)
        uris_with_counts = {}
        result.each do |r|
          uri = r[:uri].to_s
          next if uri.blank?
          uris_with_counts[uri] = r[:count].to_i
        end
        uris_with_counts
      end

      def counts_of_all_measurement_value_uris
        EOL::Sparql::Client.if_connection_fails_return({}) do
          result = query("
            SELECT ?uri, COUNT(DISTINCT ?measurement) as ?count
            WHERE {
              ?measurement dwc:measurementValue ?uri .
              FILTER (isURI(?uri))
            }
            GROUP BY ?uri
            ORDER BY DESC(?count)")
          group_counts_by_uri(result)
        end
      end

      def counts_of_all_association_type_uris
        EOL::Sparql::Client.if_connection_fails_return({}) do
          result = query("
            SELECT ?uri, COUNT(DISTINCT ?association) as ?count
            WHERE {
              ?association eol:associationType ?uri .
              FILTER (isURI(?uri))
            }
            GROUP BY ?uri
            ORDER BY DESC(?count)")
          group_counts_by_uri(result)
        end
      end

      def counts_of_all_measurement_unit_uris
        EOL::Sparql::Client.if_connection_fails_return({}) do
          result = query("
            SELECT ?uri, COUNT(DISTINCT ?measurement) as ?count
            WHERE {
              ?measurement dwc:measurementUnit ?uri .
              FILTER (isURI(?uri))
            }
            GROUP BY ?uri
            ORDER BY DESC(?count)")
          group_counts_by_uri(result)
        end
      end

      def counts_of_all_measurement_type_uris
        EOL::Sparql::Client.if_connection_fails_return({}) do
          result = query("
            SELECT ?uri, COUNT(DISTINCT ?measurement) as ?count WHERE {
              ?measurement dwc:measurementType ?uri .
              ?measurement eol:measurementOfTaxon eolterms:true .
              FILTER (isURI(?uri))
            }
            GROUP BY ?uri
            ORDER BY DESC(?count)")
          group_counts_by_uri(result)
        end
      end

      def counts_of_all_value_uris_by_type
        EOL::Sparql::Client.if_connection_fails_return({}) do
          result = query("
            SELECT ?uri, COUNT(*) as ?count WHERE {
              SELECT DISTINCT ?uri, ?value WHERE {
                ?measurement dwc:measurementType ?uri .
                ?measurement dwc:measurementValue ?value .
                ?measurement eol:measurementOfTaxon eolterms:true .
                FILTER (isURI(?uri)) .
                FILTER (isURI(?value))
              }
            }
            GROUP BY ?uri")
          group_counts_by_uri(result)
        end
      end

      def counts_of_all_measurement_type_uris_in_clade(taxon_concept)
        common_clause = "
          ?measurement dwc:measurementType ?uri .
          ?measurement eol:measurementOfTaxon ?measurementOfTaxon .
          ?measurement dwc:occurrenceID ?occurrence_id .
          ?occurrence_id dwc:taxonID ?taxon_id .
          ?taxon_id dwc:taxonConceptID ?taxon_concept_id .
          FILTER (isURI(?uri))"
        EOL::Sparql::Client.if_connection_fails_return({}) do
          result = query("SELECT ?uri, ?measurementOfTaxon, COUNT(DISTINCT ?measurement) as ?count WHERE {
              {
                SELECT ?uri, ?measurement, ?measurementOfTaxon WHERE {
                  #{ common_clause } .
                  ?taxon_id dwc:taxonConceptID <#{ KnownUri.taxon_uri(taxon_concept) }> .
                }
              } UNION {
                SELECT ?uri, ?measurement, ?measurementOfTaxon WHERE {
                  #{ common_clause } .
                  ?parent_taxon dwc:taxonConceptID <#{ KnownUri.taxon_uri(taxon_concept) }> .
                  ?t dwc:parentNameUsageID+ ?parent_taxon .
                  ?t dwc:taxonConceptID ?taxon_concept_id
                }
              }
            }
            GROUP BY ?uri ?measurementOfTaxon
            ORDER BY DESC(?count)").delete_if { |r| r[:measurementOfTaxon] != Rails.configuration.uri_true }
          group_counts_by_uri(result)
        end
      end

    end
  end
end
