module EOL
  module Sparql
    class ImportOntologyMapping < EOL::Sparql::Importer

      # this creates a named graph with some ontology mapping rules
      # in virtuoso you can run this to create a rule set:
      #    rdfs_rule_set ('http://eol.org/ontology_mappings', 'http://eol.org/ontology_mappings');
      # you can delete a rule set with:
      #    delete from sys_rdf_schema where RS_NAME='http://eol.org/ontology_mappings';
      # lear more at http://docs.openlinksw.com/virtuoso/rdfsparqlrule.html

      def initialize(options={})
        super(options)
        self.graph_name ||= "http://eol.org/ontology_mappings"
      end

      def begin
        sparql_client.delete_graph(graph_name)
        data = []
        # data << "anage:temperature owl:sameAs obis:mintemperature"
        # data << "obis:mintemperature owl:sameAs anage:temperature"
        sparql_client.insert_data(:data => data, :graph_name => graph_name)
      end

    end
  end
end