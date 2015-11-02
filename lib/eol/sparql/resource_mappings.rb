module EOL
  module Sparql
    # TODO: The name is stupid, but it's a lot of work to rename everything
    # associated with it. This is really just a list of which entries are in
    # which taxon concepts.
    class EntryToTaxonMap
      def self.create_graph(resource)
        sparql = EOL::Sparql::Connection.new
        entry_to_taxon_graph = sparql.entry_to_taxon_graph_name(resource)
        triples = Set.new
        HierarchyEntry.has_identifier.
          where(hierarchy_id: resource.hierarchy_id).
          select("id, identifier, taxon_concept_id").find_each do |entry|
          triples <<
            "<#{sparql.entry_uri(entry, resource: resource)}> "\
            "dwc:taxonConceptID "\
            "<#{sparql.taxon_concept_uri(entry.taxon_concept_id)}>"
        end
        sparql.delete_graph(entry_to_taxon_graph)
        sparql.insert_into_graph(entry_to_taxon_graph, triples)
      end
    end
  end
end
