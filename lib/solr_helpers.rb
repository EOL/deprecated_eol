# module for methods used in administrative tasks like specs and scenarios. Not recommended for production.
module SolrHelpers

  def self.recreate_solr_indexes
    solr = SolrAPI.new($SOLR_SERVER, $SOLR_TAXON_CONCEPTS_CORE)
    solr.delete_all_documents
    solr.build_indexes
  end

end
