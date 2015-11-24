describe EOL::Sparql::EntryToTaxonMap do
  describe ".create_graph" do
    # Needs a resource to pass in (just with an id) which maps to a hierarchy,
    # which has a bunch of hierarchy entries (subject) that are mapped to taxon
    # concepts (object). The result should be a graph with ONLY those items in
    # it (with a predicate of dwc:taxonConceptID). You could, of course, have to
    # read Virtuoso to see that it worked... or you could stub
    # EOL::Sparql.connection with something that will receive :insert_data with
    # (data: [array of strings of triples], graph_name: [string of the mapping
    # graph name for the resource]) ...but that might be more trouble than it's
    # worth!
  end
end
