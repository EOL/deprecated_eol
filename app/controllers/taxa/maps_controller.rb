class Taxa::MapsController < TaxaController
  before_filter :instantiate_taxon_concept
  
  def show
    @taxon_concept.current_user = current_user
    @curator = @taxon_concept.current_user.can_curate?(@taxon_concept)
    @assistive_section_header = I18n.t(:assistive_maps_header)
    current_user.log_activity(:viewed_taxon_concept_maps, :taxon_concept_id => @taxon_concept.id)
  end
end
