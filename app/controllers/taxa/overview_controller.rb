class Taxa::OverviewController < TaxaController

  layout 'taxa'

  before_filter :instantiate_taxon_page,
    :redirect_if_superceded,
    :instantiate_preferred_names

  def show
    with_master_if_curator do
      @overview = @taxon_page.overview
      @traits = []
      @traits = PageTraits.new(@taxon_concept.id) if EolConfig.data?
      @range_data = []
    end
    @assistive_section_header = I18n.t(:assistive_overview_header)
    @rel_canonical_href = taxon_overview_url(@overview)
  end
end
