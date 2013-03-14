module EOL
  module Sparql
    class Endpoint

      attr_accessor :endpoint_uri, :namespaces, :username, :password, :sparql_client

      def initialize(options={})
        self.endpoint_uri = options[:endpoint_uri]
        self.username = options[:username]
        self.password = options[:password]
        self.namespaces = EOL::Sparql.common_namespaces
        self.sparql_client = SPARQL::Client.new(self.endpoint_uri)
      end

      def insert_data(options={})
      end

      def delete_graph(graph_name)
      end

      def sparql_update(query)
        sparql_client.query(query)
      end

      def delete_graph(graph_name)
        delete_graph_via_sparql_update(graph_name)
      end

      def delete_graph_via_sparql_update(graph_name)
        sparql_update("CLEAR GRAPH <#{graph_name}>")
        sparql_update("DROP SILENT GRAPH <#{graph_name}>")
      end

      def query(query)
        results = []
        sparql_client.query(query).each_solution{ |s| results << s.to_hash }
        results
      end

    end
  end
end
