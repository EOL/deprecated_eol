class Taxa::MapsController < TaxaController
  before_filter :instantiate_taxon_concept
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    # TODO - On next line @curator is defined and doesn't seem to be used anywhere for maps tab. Remove it if not really needed.
    @curator = current_user.min_curator_level?(:full)
    @assistive_section_header = I18n.t(:assistive_maps_header)
    current_user.log_activity(:viewed_taxon_concept_maps, :taxon_concept_id => @taxon_concept.id)
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @maps = @taxon_concept.map_images
  end
end
