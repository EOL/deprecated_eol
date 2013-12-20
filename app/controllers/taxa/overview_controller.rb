class Taxa::OverviewController < TaxaController

  layout 'v2/taxa'

  prepend_before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN   # if we happen to be on an SSL page, go back to http

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def show
    @overview = @taxon_page.overview
    if current_user.can_see_data?
      @all_data_point_uris_count = @taxon_page.data.distinct_predicates.count
      @overview_data_point_uris = @taxon_page.data.get_data_for_overview
      @range_data = @taxon_page.data.ranges_for_overview
    end
    @assistive_section_header = I18n.t(:assistive_overview_header)
    @rel_canonical_href = taxon_overview_url(@overview)
    current_user.log_activity(:viewed_taxon_concept_overview, taxon_concept_id: @taxon_concept.id)
  end

end
