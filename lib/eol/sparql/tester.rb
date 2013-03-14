module EOL
  module Sparql
    class Tester

      attr_accessor :virtuoso, :four_store, :ranks, :data_types, :taxa_graph_name, :data_object_graph_name, :debug

      def initialize
        self.virtuoso = EOL::Sparql.virtuoso_connection
        self.four_store = EOL::Sparql.four_store_connection
        self.ranks = [ 'kingdom', 'phylum', 'class', 'order', 'family', 'genus', 'species' ]
        self.data_types = [ 'Text', 'StillImage', 'MovingImage', 'Sound' ]
        self.taxa_graph_name = "http://testing/taxa"
        self.data_object_graph_name = "http://testing/data_objects"
        # self.debug = true
      end

      def begin
        virtuoso.delete_graph_via_sparql_update(taxa_graph_name)
        virtuoso.delete_graph_via_sparql_update(data_object_graph_name)
        four_store.delete_graph_via_sparql_update(taxa_graph_name)
        four_store.delete_graph_via_sparql_update(data_object_graph_name)

        virtuoso_load_time = 0
        four_store_load_time = 0
        # 10 letters * 10000 entities * 4 triples per entity * 2 graphs = 800,000 triples
        ('a'..'j').to_a.each do |batch|
          taxa_data = []
          object_data_data = []
          10000.times do |i|
            data_line = "<http://eol.org/pages/#{i}#{batch}> a dwct:Taxon"
            data_line += "; dwc:scientificName \"Name string#{i}#{batch}\""
            data_line += "; dwc:taxonConceptID <http://eol.org/concepts/#{i}#{batch}>"
            data_line += "; dwc:taxonRank <http://eol.org/ranks/#{ranks.sample}>"
            taxa_data << data_line

            data_line = "<http://eol.org/data_objects/#{i}#{batch}> a eol:DataObject"
            data_line += "; dc:title \"Data object#{i}#{batch}\""
            data_line += "; dwc:taxonConceptID <http://eol.org/concepts/#{i}#{batch}>"
            data_line += "; dc:type <http://purl.org/dc/dcmitype/#{data_types.sample}>"
            object_data_data << data_line
          end

          start = Time.now
          puts "Inserting Virtuoso #{batch} of j..."
          virtuoso.insert_data(:data => taxa_data, :graph_name => taxa_graph_name)
          virtuoso.insert_data(:data => object_data_data, :graph_name => data_object_graph_name)
          virtuoso_load_time += Time.now - start

          start = Time.now
          puts "Inserting 4store #{batch} of j..."
          four_store.insert_data(:data => taxa_data, :graph_name => taxa_graph_name)
          four_store.insert_data(:data => object_data_data, :graph_name => data_object_graph_name)
          four_store_load_time += Time.now - start
        end

        puts "\n\n=============="
        puts "Virtuoso"
        puts "  Load time =>\t\t\t#{virtuoso_load_time.round(2)} seconds"
        evaluate(virtuoso)

        puts "\n\n=============="
        puts "4Store"
        puts "  Load time =>\t\t\t#{four_store_load_time.round(2)} seconds"
        evaluate(four_store)
      end

      def evaluate(sparql_client)
        individual_query_iterations = 5000
        concept_query_iterations = 5000
        name_query_iterations = 5000
        simple_conditional_iterations = 5000
        cross_graph_iterations = 3000

        all_test_start_time = Time.now
        taxa_count = sparql_client.query("SELECT (COUNT(*) as ?c) FROM <#{taxa_graph_name}> WHERE { ?s ?p ?o }").first[:c].to_i
        object_count = sparql_client.query("SELECT (COUNT(*) as ?c) FROM <#{data_object_graph_name}> WHERE { ?s ?p ?o }").first[:c].to_i
        puts "  Number of taxa triples =>\t#{taxa_count}"
        puts "  Number of object triples =>\t#{object_count}"
        puts "  Count time =>\t\t\t#{(Time.now - all_test_start_time).round(4)} seconds"
        puts "  Tests"

        query = "\"SELECT ?p ?o FROM <#{taxa_graph_name}> WHERE { <http://eol.org/pages/%s> ?p ?o }\" % [ random_id ]"
        test_query('individuals', query, individual_query_iterations, sparql_client)

        query = "\"SELECT ?s FROM <#{taxa_graph_name}>
          WHERE { ?s <http://rs.tdwg.org/dwc/terms/taxonConceptID> <http://eol.org/concepts/%s> }\" % [ random_id ]"
        test_query('concepts', query, concept_query_iterations, sparql_client)

        query = "\"SELECT ?s FROM <#{taxa_graph_name}>
          WHERE { ?s <http://rs.tdwg.org/dwc/terms/scientificName> \\\"Name string#{random_id}\\\" }\" % [ random_id ]"
        test_query('names', query, name_query_iterations, sparql_client)

        query = "\"SELECT ?s FROM <#{taxa_graph_name}>
          WHERE { ?s <http://rs.tdwg.org/dwc/terms/taxonConceptID> <http://eol.org/concepts/%s> .
                  ?s <http://rs.tdwg.org/dwc/terms/taxonRank> <http://eol.org/ranks/%s> . }\" % [ random_id, ranks.sample ]"
        test_query('basic conditional', query, simple_conditional_iterations, sparql_client)

        query = "\"SELECT ?taxon ?rank ?concept_id ?data_object ?data_type
          WHERE { ?taxon a <http://rs.tdwg.org/dwc/dwctype/Taxon> .
                  ?taxon <http://rs.tdwg.org/dwc/terms/taxonConceptID> <http://eol.org/concepts/%s> .
                  ?taxon <http://rs.tdwg.org/dwc/terms/taxonConceptID> ?concept_id .
                  ?taxon <http://rs.tdwg.org/dwc/terms/taxonRank> ?rank .
                  ?data_object a <http://eol.org/schema/terms/DataObject> .
                  ?data_object <http://rs.tdwg.org/dwc/terms/taxonConceptID> ?concept_id .
                  ?data_object <http://purl.org/dc/terms/type> ?data_type }\" % [ random_id ]"
        test_query('cross graphs', query, cross_graph_iterations, sparql_client)

        start = Time.now
        sparql_client.delete_graph_via_sparql_update(taxa_graph_name)
        sparql_client.delete_graph_via_sparql_update(data_object_graph_name)
        report_for_test("deleting graphs", Time.now - start, nil)

        puts "\n    all tests finished in #{(Time.now - all_test_start_time).round(2)} seconds"
      end

      def test_query(test_name, query_to_eval, iterations, sparql_client)
        start = Time.now
        iterations.times do |i|
          query = eval(query_to_eval)
          result = sparql_client.query(query)
          if debug && i == 0
            puts "\n==========\nQuery:\n"
            puts query
            puts "\n==========\nResult:\n"
            pp result
          end
        end
        report_for_test(test_name, Time.now - start, iterations)
      end

      def random_id
        @letters ||= ('a'..'j').to_a
        Random.rand(10000).to_s + @letters.sample
      end

      def report_for_test(test_name, duration, iterations)
        puts "    results of #{test_name}"
        puts "      iterations =>\t\t#{iterations}" if iterations
        puts "      duration =>\t\t#{duration.round(2)} seconds" if duration
        puts "      queries/sec =>\t\t#{(iterations/duration).round(2)}" if duration && iterations
      end

    end
  end
end