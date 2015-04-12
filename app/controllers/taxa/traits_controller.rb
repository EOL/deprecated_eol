class TraitsController < TaxaController
  before_filter :instantiate_taxon_page, :redirect_if_superceded

  def index
    load_traits
  end

  def about
    # TODO
  end

  def glossary
    #TODO
  end

  def ranges
    #TODO
  end

  private

  def load_traits
    # TODO: IndexMeta / PageMeta / Canonical URLs (see ContentPartnersController)
    @traits = Page::Traits.new(@taxon_page)
    @toc_id =  params[:toc_id]
    @trait_id = params[:trait_id].to_i
  end
end
