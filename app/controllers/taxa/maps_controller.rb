class Taxa::MapsController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    # TODO - On next line @curator is defined and doesn't seem to be used anywhere for maps tab. Remove it if not really needed.
    @curator = current_user.min_curator_level?(:full)
    @assistive_section_header = I18n.t(:assistive_maps_header)
    current_user.log_activity(:viewed_taxon_concept_maps, :taxon_concept_id => @taxon_concept.id)
    @watch_collection = logged_in? ? current_user.watch_collection : nil
    @maps = @taxon_concept.map_images
  end

protected
  def set_meta_title
    I18n.t(:meta_title_template,
      :page_title => [
        @preferred_common_name ? I18n.t(:meta_title_taxon_maps_with_common_name,
        :preferred_common_name => @preferred_common_name) : nil,
        @scientific_name,
        @assistive_section_header,
        @selected_hierarchy_entry ? @selected_hierarchy_entry.hierarchy_label : nil,
      ].compact.join(" - "))
  end
  def set_meta_description
    if @selected_hierarchy_entry
      @preferred_common_name ?
        I18n.t(:meta_description_hierarchy_entry_maps_with_common_name, :scientific_name => @scientific_name,
          :hierarchy_provider => @selected_hierarchy_entry.hierarchy_label,
          :preferred_common_name => @preferred_common_name) :
        I18n.t(:meta_description_hierarchy_entry_maps, :scientific_name => @scientific_name,
          :hierarchy_provider => @selected_hierarchy_entry.hierarchy_label)
    else
      @preferred_common_name ?
        I18n.t(:meta_description_taxon_maps_with_common_name, :scientific_name => @scientific_name,
          :preferred_common_name => @preferred_common_name) :
        I18n.t(:meta_description_taxon_maps, :scientific_name => @scientific_name)
    end
  end
  def additional_meta_keywords
   [ @preferred_common_name ?
      I18n.t(:meta_keywords_taxon_maps_with_common_name, :preferred_common_name => @preferred_common_name) :
      I18n.t(:meta_keywords_taxon_maps) ]
  end
end
