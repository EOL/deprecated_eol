class Taxa::UpdatesController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    @assistive_section_header = I18n.t(:assistive_updates_header)
    @page = params[:page]
    @taxon_activity_log = @taxon_concept.activity_log(:per_page => 10, :page => @page)
    if @selected_hierarchy_entry
      @rel_canonical_href = taxon_hierarchy_entry_updates_url(@taxon_concept, @selected_hierarchy_entry, :page => rel_canonical_href_page_number(@taxon_activity_log))
      @rel_prev_href = rel_prev_href_params(@taxon_activity_log) ? taxon_hierarchy_entry_updates_url(@rel_prev_href_params) : nil
      @rel_next_href = rel_next_href_params(@taxon_activity_log) ? taxon_hierarchy_entry_updates_url(@rel_next_href_params) : nil
    else
      @rel_canonical_href = taxon_updates_url(@taxon_concept, :page => rel_canonical_href_page_number(@taxon_activity_log))
      @rel_prev_href = rel_prev_href_params(@taxon_activity_log) ? taxon_updates_url(@rel_prev_href_params) : nil
      @rel_next_href = rel_next_href_params(@taxon_activity_log) ? taxon_updates_url(@rel_next_href_params) : nil
    end
    current_user.log_activity(:viewed_taxon_concept_updates, :taxon_concept_id => @taxon_concept.id)
  end

  def statistics
    @assistive_section_header = I18n.t(:assistive_updates_statistics_header)
    current_user.log_activity(:viewed_taxon_concept_statistics, :taxon_concept_id => @taxon_concept.id)
    @metrics = @taxon_concept.taxon_concept_metric
    @media_facets = @taxon_concept.media_facet_counts
    @rel_canonical_href = @selected_hierarchy_entry ?
      statistics_taxon_hierarchy_entry_updates_url(@taxon_concept, @selected_hierarchy_entry) :
      statistics_taxon_updates_url(@taxon_concept)
  end

end
