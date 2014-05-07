class TaxonConceptExemplarImagesController < TaxaController

  before_filter :restrict_to_curators

  def create
    @taxon_concept_exemplar_image = TaxonConceptExemplarImage.new(params[:taxon_concept_exemplar_image])
    TaxonConceptExemplarImage.set_exemplar(@taxon_concept_exemplar_image)
    log_action(@taxon_concept_exemplar_image.taxon_concept, @taxon_concept_exemplar_image.data_object, :choose_exemplar_image)
    store_location(params[:return_to] || request.referer)
    respond_to do |format|
      format.html { redirect_back_or_default taxon_media_path(@taxon_concept_exemplar_image.taxon_concept) }
      format.js {}
    end
  end

end
