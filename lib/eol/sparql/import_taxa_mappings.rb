module EOL
  module Sparql
    class ImportTaxaMappings < EOL::Sparql::Importer

      def initialize(options={})
        super(options)
        self.graph_name ||= "http://eol.org/taxon_mappings/"
      end

      def begin
        sparql_client.delete_graph(graph_name)
        data = []
        data << "<http://anage.org/taxa/gadus_morhua>	<http://rs.tdwg.org/dwc/terms/taxonConceptID>	<http://eol.org/pages/206692>"
        data << "<http://iobis.org/taxa/627911>	<http://rs.tdwg.org/dwc/terms/taxonConceptID>	<http://eol.org/pages/206692>"
        sparql_client.insert_data(:data => data, :graph_name => graph_name)
      end

    end
  end
end