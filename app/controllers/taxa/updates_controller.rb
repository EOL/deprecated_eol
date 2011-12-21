class Taxa::UpdatesController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    @assistive_section_header = I18n.t(:assistive_updates_header)
    @page = params[:page]
    current_user.log_activity(:viewed_taxon_concept_updates, :taxon_concept_id => @taxon_concept.id)
  end
  
  def statistics
    @assistive_section_header = I18n.t(:assistive_updates_header)
    current_user.log_activity(:viewed_taxon_concept_statistics, :taxon_concept_id => @taxon_concept.id)
    @metrics = @taxon_concept.taxon_concept_metric
    @media_facets = @taxon_concept.media_facet_counts
    
  end
  
end
