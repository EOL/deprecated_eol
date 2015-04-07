class TraitsController < TaxaController
  before_filter :instantiate_taxon_page, :redirect_if_superceded

  def index
    load_traits
  end

  private

  def load_traits
    # TODO: IndexMeta / PageMeta / Canonical URLs (see ContentPartnersController)
    @taxon_traits = Page::Traits.new(@taxon_page)
  end
end
