module EOL
  module Sparql
    class Client

      attr_accessor :endpoint_uri, :namespaces, :username, :password, :sparql_client

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
        sparql_client.query(append_namespaces_to_query(query))
      end

      def delete_graph(graph_name)
        return unless graph_name
        delete_graph_via_sparql_update(graph_name)
      end

      # NOTE: if you get an error: Invalid port number: "8890/DAV/xx/yy", then go to:
      # http://localhost:8890/ => LinkedData => Graphs and check to see if there is a graph named
      # http://localhost:8890%2FDAV%2Fxx%2Fyy . If so, delete it and try again
      def query(query, options = {})
        query = append_namespaces_to_query(query)
        query = options[:prefix] +" "+ query if options[:prefix]
        results = []
        # puts "\n\n\n\n\n\n*********************"
        # puts query
        sparql_client.query(query).each_solution{ |s| results << s.to_hash }
        # puts "done"
        results
      end

      private

      def delete_graph_via_sparql_update(graph_name)
        return unless graph_name
        update("CLEAR GRAPH <#{graph_name}>")
        update("DROP SILENT GRAPH <#{graph_name}>")
      end

      def append_namespaces_to_query(query)
        namespaces.collect{ |key,value| "PREFIX #{key}: <#{value}>"}.join(" ") + " " + query
      end
    end
  end
end
