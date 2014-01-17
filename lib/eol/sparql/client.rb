module EOL
  module Sparql
    class Client

      attr_accessor :endpoint_uri, :namespaces, :username, :password, :sparql_client
      extend EOL::Sparql::SafeConnection # Note we ONLY need the class methods, so #extend
      extend EOL::LocalCacheable

      def initialize(options={})
        @endpoint_uri = options[:endpoint_uri]
        @username = options[:username]
        @password = options[:password]
        @namespaces = EOL::Sparql::NAMESPACES
        @sparql_client = SPARQL::Client.new(endpoint_uri)
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

      # NOTE: if you get an error: Invalid port number: "8890/DAV/xx/yy", then go to:
      # http://localhost:8890/ => LinkedData => Graphs and check to see if there is a graph named
      # http://localhost:8890%2FDAV%2Fxx%2Fyy . If so, delete it and try again
      def query(query, options = {})
        results = []
        begin
          if Rails.configuration.respond_to?('show_sparql_queries') && Rails.configuration.show_sparql_queries
            puts "#{options[:prefix]}\n#{namespaces_prefixes}\n#{query}"
          end
          sparql_client.query("#{options[:prefix]} #{namespaces_prefixes} #{query}").each_solution { |s| results << s.to_hash }
        rescue Errno::ECONNREFUSED => e
          logger.error "** ERROR: Virtuoso Connection refused: #{e.message}"
          raise EOL::Exceptions::SparqlDataEmpty # This gets caught by our code gracefully.
        rescue ArgumentError => e
          # NOTE - this catch is caused by going through the demo for setting up the DAV user/directory. You've got to manually delete that
          # later!
          if e.message =~ /Invalid port number/
            puts "We found a graph that cannot be removed programmatically."
            puts "Please go to http://localhost:8890/ => Conductor => LinkedData => Graphs and check to see"
            puts "if there is a graph named http://localhost:8890%2FDAV%2Fxx%2Fyy ...if so, delete it and"
            puts "try again. Sorry!"
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
        self.class.cache_fetch_with_local_timeout("eol/sparql/client/all_measurement_type_uris", :expires_in => 1.day) do
          counts_of_all_measurement_type_uris.collect{ |k,v| k }
        end
      end

      def all_measurement_type_known_uris
        self.class.cache_fetch_with_local_timeout("eol/sparql/client/all_measurement_type_known_uris", :expires_in => 1.day) do
          all_uris = all_measurement_type_uris
          all_known_uris = KnownUri.find_all_by_uri(all_uris)
          all_uris.collect{ |uri| all_known_uris.detect{ |kn| kn.uri == uri } || uri }
        end
      end

      def all_measurement_type_known_uris_for_clade(taxon_concept)
        self.class.cache_fetch_with_local_timeout("eol/sparql/client/all_measurement_type_known_uris_for_clade/#{taxon_concept.id}", :expires_in => 1.day) do
          all_uris = counts_of_all_measurement_type_uris_in_clade(taxon_concept).collect{ |k,v| k }
          all_known_uris = KnownUri.find_all_by_uri(all_uris)
          all_uris.collect{ |uri| all_known_uris.detect{ |kn| kn.uri == uri } || uri }
        end
      end

    private

      def delete_graph_via_sparql_update(graph_name)
        return unless graph_name
        update("CLEAR GRAPH <#{graph_name}>")
        update("DROP SILENT GRAPH <#{graph_name}>")
      end

      def namespaces_prefixes
        namespaces.collect{ |key,value| "PREFIX #{key}: <#{value}>"}.join(" ")
      end

      def unknown_uris_from_array(uris_with_counts)
        unknown_uris_with_counts = uris_with_counts
        known_uris = KnownUri.find_all_by_uri(unknown_uris_with_counts.collect{ |uri,count| uri })
        known_uris.each do |known_uri|
          unknown_uris_with_counts.delete_if{ |uri, count| known_uri.matches(uri) }
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
          result = query("SELECT ?uri, COUNT(DISTINCT ?measurement) as ?count
            WHERE {
              ?measurement dwc:measurementValue ?uri .
              FILTER (isURI(?uri))
            }
            GROUP BY ?uri
            ORDER BY DESC(?count)
          ")
          group_counts_by_uri(result)
        end
      end

      def counts_of_all_association_type_uris
        EOL::Sparql::Client.if_connection_fails_return({}) do
          result = query("SELECT ?uri, COUNT(DISTINCT ?association) as ?count
            WHERE {
              ?association eol:associationType ?uri .
              FILTER (isURI(?uri))
            }
            GROUP BY ?uri
            ORDER BY DESC(?count)
          ")
          group_counts_by_uri(result)
        end
      end

      def counts_of_all_measurement_unit_uris
        EOL::Sparql::Client.if_connection_fails_return({}) do
          result = query("SELECT ?uri, COUNT(DISTINCT ?measurement) as ?count
            WHERE {
              ?measurement dwc:measurementUnit ?uri .
              FILTER (isURI(?uri))
            }
            GROUP BY ?uri
            ORDER BY DESC(?count)
          ")
          group_counts_by_uri(result)
        end
      end

      def counts_of_all_measurement_type_uris
        EOL::Sparql::Client.if_connection_fails_return({}) do
          result = query("SELECT ?uri, COUNT(DISTINCT ?measurement) as ?count
            WHERE {
              ?measurement dwc:measurementType ?uri .
              ?measurement eol:measurementOfTaxon ?measurementOfTaxon .
              FILTER ( ?measurementOfTaxon = 'true' ) .
              FILTER (isURI(?uri))
            }
            GROUP BY ?uri
            ORDER BY DESC(?count)
          ")
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
          FILTER ( ?measurementOfTaxon = 'true' ) .
          FILTER (isURI(?uri))"
        EOL::Sparql::Client.if_connection_fails_return({}) do
          result = query("SELECT ?uri, COUNT(DISTINCT ?measurement) as ?count WHERE {
              {
                SELECT ?uri, ?measurement WHERE {
                  #{ common_clause } .
                  ?taxon_id dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept.id}> .
                }
              } UNION {
                SELECT ?uri, ?measurement WHERE {
                  #{ common_clause } .
                  ?parent_taxon dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept.id}> .
                  ?t dwc:parentNameUsageID+ ?parent_taxon .
                  ?t dwc:taxonConceptID ?taxon_concept_id
                }
              }
            }
            GROUP BY ?uri
            ORDER BY DESC(?count)")
          group_counts_by_uri(result)
        end
      end

    end
  end
end
