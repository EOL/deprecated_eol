module EOL
  module Sparql
    class Importer

      attr_accessor :graph_name, :sparql_client

      def initialize(options={})
        self.graph_name = options[:graph_name]
        if options[:triplestore] == :four_store
          self.sparql_client = EOL::Sparql.four_store_connection
        else
          self.sparql_client = EOL::Sparql.virtuoso_connection
        end
      end

    end
  end
end