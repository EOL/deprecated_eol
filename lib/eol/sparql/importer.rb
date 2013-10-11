module EOL
  module Sparql
    class Importer

      attr_accessor :graph_name, :sparql_client

      def initialize(options={})
        self.graph_name = options[:graph_name]
        self.sparql_client = EOL::Sparql.connection
      end

    end
  end
end