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

      def update(query)
        sparql_client.query(append_namespaces_to_query(query))
      end

      def delete_graph(graph_name)
        return unless graph_name
        delete_graph_via_sparql_update(graph_name)
      end

      def query(query)
        results = []
        sparql_client.query(append_namespaces_to_query(query)).each_solution{ |s| results << s.to_hash }
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
