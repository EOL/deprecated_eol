class TraitBankController < ApplicationController

  layout "taxa"

  def show
    @taxon_concept = TaxonConcept.find(params[:id])
    @taxon_page = TaxonPage.new(@taxon_concept, current_user)
    @scientific_name = @taxon_page.title
    @page_traits = PageTraits.new(params[:id])
  end
end
