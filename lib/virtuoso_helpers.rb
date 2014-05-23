# Module to be *included* (these aren't class methods) for helping out with Virtuoso in administrative tasks like specs and
# scenarios. Not menat for production (dangerous).
module VirtuosoHelpers

  def drop_all_virtuoso_graphs
    EOL::Sparql.connection.query("SELECT ?graph WHERE { GRAPH ?graph { ?s ?p ?o } } GROUP BY ?graph").each do |result|
      graph_name = result[:graph].to_s
      if graph_name =~ /^http:\/\/eol\.org\//
        EOL::Sparql.connection.delete_graph(graph_name)
      end
    end
  end

end
