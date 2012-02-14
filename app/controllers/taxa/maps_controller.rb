class Taxa::MapsController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    # TODO - On next line @curator is defined and doesn't seem to be used anywhere for maps tab. Remove it if not really needed.
    @curator = current_user.min_curator_level?(:full)
    @assistive_section_header = I18n.t(:assistive_maps_header)
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @maps = @taxon_concept.map_images
    @rel_canonical_href = @selected_hierarchy_entry ?
      taxon_hierarchy_entry_maps_url(@taxon_concept, @selected_hierarchy_entry) :
      taxon_maps_url(@taxon_concept)
    current_user.log_activity(:viewed_taxon_concept_maps, :taxon_concept_id => @taxon_concept.id)
  end

end
