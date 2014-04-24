class Taxa::OverviewController < TaxaController

  layout 'taxa'

  prepend_before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN   # if we happen to be on an SSL page, go back to http

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def show
    @overview = @taxon_page.overview
    @data = @taxon_page.data
    @overview_data = @data.get_data_for_overview
    @range_data = @data.ranges_for_overview
    @assistive_section_header = I18n.t(:assistive_overview_header)
    @rel_canonical_href = taxon_overview_url(@overview)
    # TODO: remove this hard-coded exception. We are testing the JSON-LD
    # data for Passeriformes, Mammalia and Salmoniformes
    clade_ids = [ 1596, 1642, 5157 ]
    if clade_ids.include?(@taxon_concept.id) || !(@taxon_concept.flattened_ancestor_ids & clade_ids).empty?
      make_json_ld
    end
    current_user.log_activity(:viewed_taxon_concept_overview, taxon_concept_id: @taxon_concept.id)
  end

  private

  def make_json_ld
    @jsonld = { '@context' => {
                  'dc' => 'http://purl.org/dc/terms/',
                  'dwc' => 'http://rs.tdwg.org/dwc/terms/',
                  'eol' => 'http://eol.org/schema/',
                  'eolterms' => 'http://eol.org/schema/terms/',
                  'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
                  'gbif' => 'http://rs.gbif.org/terms/1.0/',
                  'dwc:taxonID' => { '@type' => '@id' },
                  'eol:associationType' => { '@type' => '@id' },
                  'dwc:vernacularName' => { '@container' => '@language' },
                  'rdfs:label' => { '@container' => '@language' }
                } }
    @jsonld['@graph'] = [ @taxon_concept.to_jsonld ]
    @jsonld['@graph'] += @taxon_concept.common_names.collect{ |tcn| tcn.to_jsonld }
    @jsonld['@graph'] += @data.get_data.collect{ |d| d.to_jsonld }
    @jsonld['@graph']
  end

end
