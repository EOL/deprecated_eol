class Taxa::MapsController < TaxaController
  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names

  def index
    # TODO - On next line @curator is defined and doesn't seem to be used anywhere for maps tab. Remove it if not really needed.
    @curator = current_user.min_curator_level?(:full)
    @assistive_section_header = I18n.t(:assistive_maps_header)

    @maps = @taxon_concept.data_objects_from_solr({
      page: 1,
      per_page: 100,
      data_type_ids: DataType.image_type_ids,
      data_subtype_ids: DataType.map_type_ids,
      vetted_types: current_user.vetted_types,
      visibility_types: current_user.visibility_types,
      ignore_translations: true
    })
    DataObject.preload_associations(@maps, [ :users_data_objects_ratings, { data_objects_hierarchy_entries:
      [ :hierarchy_entry, :vetted, :visibility ] } ] )
    @rel_canonical_href = taxon_maps_url(@taxon_page)
  end

protected
  def meta_description
    @meta_description ||= t(".meta_description#{scoped_variables_for_translations[:preferred_common_name] ? '_with_common_name' : ''}#{@maps.blank? ? '_no_data' : ''}", scoped_variables_for_translations.dup)
  end

end
