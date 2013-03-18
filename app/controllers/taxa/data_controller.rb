class Taxa::DataController < TaxaController
  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @assistive_section_header = "ASdfsfasdfasdfasdaf"
    @data =
      EOL::Sparql.connection.query("SELECT DISTINCT ?attribute ?value ?user_added_data_id
        FROM <#{UserAddedData.graph_name}>
        WHERE { ?user_added_data_id <http://rs.tdwg.org/dwc/terms/taxonConceptID> <http://eol.org/pages/#{@taxon_concept.id}> .
          ?user_added_data_id <http://rs.tdwg.org/dwc/terms/measurementType> ?attribute .
          ?user_added_data_id <http://rs.tdwg.org/dwc/terms/measurementValue> ?value }
        ORDER BY ?attribute") +
      EOL::Sparql.connection.query("SELECT DISTINCT ?attribute ?value
        WHERE {
          ?taxon <http://rs.tdwg.org/dwc/terms/taxonConceptID> <http://eol.org/pages/#{@taxon_concept.id}> .
          ?taxon <http://eol.org/schema/terms/canonical> ?canonical .
          ?othertaxon <http://eol.org/schema/terms/canonical> ?canonical .
          ?othertaxon ?attribute ?value }
        ORDER BY ?attribute")
    current_user.log_activity(:viewed_taxon_concept_data, :taxon_concept_id => @taxon_concept.id)
  end

protected
  def meta_description
    @meta_description ||= "this is so meta"
  end

end
