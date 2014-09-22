# This is meant to be #include'd.
module VirtuosoHelpers
  def drop_all_virtuoso_graphs
    EOL::Sparql::VirtuosoClient.drop_all_graphs
  end
end
