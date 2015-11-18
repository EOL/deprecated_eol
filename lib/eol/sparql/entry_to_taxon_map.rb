module EOL
  module Sparql
    class EntryToTaxonMap
      def self.create_graph(resource)
        EOL.log_call
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
        puts "Graph: #{entry_to_taxon_graph}"
        sparql.delete_graph(entry_to_taxon_graph)
        puts "Whoa, adding:"
        pp triples
        sparql.insert_into_graph(entry_to_taxon_graph, triples.to_a)
      end
    end
  end
end
