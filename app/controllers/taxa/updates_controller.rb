class Taxa::UpdatesController < TaxaController
  before_filter :instantiate_taxon_concept

  def show
    @assistive_section_header = I18n.t(:assistive_updates_header)
    @page = params[:page]
    current_user.log_activity(:viewed_taxon_concept_updates, :taxon_concept_id => @taxon_concept.id)
  end
end
