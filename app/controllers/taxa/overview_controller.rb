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
    if false # Temporarily disabling this.
      if clade_ids.include?(@taxon_concept.id) || !(@taxon_concept.flattened_ancestor_ids & clade_ids).empty?
        make_json_ld
      end
    end
    current_user.log_activity(:viewed_taxon_concept_overview, taxon_concept_id: @taxon_concept.id)
  end

  private

  def make_json_ld
    @jsonld = EOL::Api::Traits::V1_0.prepare_hash(@taxon_concept, data: @data)
  end

end
