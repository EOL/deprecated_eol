class Taxa::DetailsController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  # GET /pages/:taxon_id/details
  def index
    
    @text_objects = @taxon_concept.details_text_for_user(current_user)
    @toc_items_to_show = @taxon_concept.table_of_contents_for_text(@text_objects)
    
    @data_objects_in_other_languages = @taxon_concept.text_for_user(current_user, {
      :language_ids_to_ignore => [ current_language.id, 0 ],
      :allow_nil_languages => false,
      :preload_select => { :data_objects => [ :id, :guid, :language_id ] },
      :skip_preload => true,
      :toc_ids_to_ignore => TocItem.exclude_from_details.collect{ |toc_item| toc_item.id } })
    DataObject.preload_associations(@data_objects_in_other_languages, :language)
    @details_count_by_language = {}
    @data_objects_in_other_languages.each do |obj|
      @details_count_by_language[obj.language] ||= 0
      @details_count_by_language[obj.language] += 1
    end
    
    @exemplar_image = @taxon_concept.exemplar_or_best_image_from_solr(@selected_hierarchy_entry)
    @assistive_section_header = I18n.t(:assistive_details_header)
    @rel_canonical_href = @selected_hierarchy_entry ?
      taxon_hierarchy_entry_details_url(@taxon_concept, @selected_hierarchy_entry) :
      taxon_details_url(@taxon_concept)
    current_user.log_activity(:viewed_taxon_concept_details, :taxon_concept_id => @taxon_concept.id)
  end

protected
  def meta_description
    chapter_list = @toc_items_to_show.collect{|i| i.label}.uniq.compact.join("; ") unless @toc_items_to_show.blank?
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:chapter_list] = chapter_list unless chapter_list.blank?
    I18n.t("meta_description#{translation_vars[:preferred_common_name] ? '_with_common_name' :
           ''}#{translation_vars[:chapter_list] ? '_with_chapter_list' : '_no_data'}",
           translation_vars)
  end
  def meta_keywords
    keywords = super
    toc_subjects = @toc_items_to_show.collect{|i| i.label}.compact.join(", ")
    [keywords, toc_subjects].compact.join(', ')
  end
end
