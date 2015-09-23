class Taxa::UpdatesController < TaxaController
  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names

  def index
    @assistive_section_header = I18n.t(:assistive_updates_header)
    @page = params[:page]
    @taxon_activity_log = @taxon_concept.activity_log(per_page: 10, page: @page, user: current_user)
    set_canonical_urls(for: @taxon_page, paginated: @taxon_activity_log, url_method: :taxon_updates_url)
  end

  def statistics
    @assistive_section_header = I18n.t(:assistive_updates_statistics_header)
    @metrics = @taxon_concept.taxon_concept_metric
    @media_facets = @taxon_concept.media_facet_counts
    @rel_canonical_href = statistics_taxon_updates_url(@taxon_page)
  end

end
