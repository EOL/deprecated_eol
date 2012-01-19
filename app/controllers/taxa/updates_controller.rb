class Taxa::UpdatesController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    @assistive_section_header = I18n.t(:assistive_updates_header)
    @page = params[:page]
    current_user.log_activity(:viewed_taxon_concept_updates, :taxon_concept_id => @taxon_concept.id)
  end

  def statistics
    @assistive_section_header = I18n.t(:assistive_updates_statistics_header)
    current_user.log_activity(:viewed_taxon_concept_statistics, :taxon_concept_id => @taxon_concept.id)
    @metrics = @taxon_concept.taxon_concept_metric
    @media_facets = @taxon_concept.media_facet_counts
  end

protected
  def set_meta_title
    I18n.t(:meta_title_template,
      :page_title => [
        @preferred_common_name ? I18n.t("meta_title_taxon_updates_#{action_name}_with_common_name",
        :preferred_common_name => @preferred_common_name, :scientific_name => @scientific_name) :
        I18n.t("meta_title_taxon_updates_#{action_name}", :scientific_name => @scientific_name),
        @assistive_section_header,
        @selected_hierarchy_entry ? @selected_hierarchy_entry.hierarchy_label : nil,
      ].compact.join(" - "))
  end
  def set_meta_description
    if @selected_hierarchy_entry
      @preferred_common_name ?
        I18n.t("meta_description_hierarchy_entry_updates_#{action_name}_with_common_name", :scientific_name => @scientific_name,
          :hierarchy_provider => @selected_hierarchy_entry.hierarchy_label,
          :preferred_common_name => @preferred_common_name) :
        I18n.t("meta_description_hierarchy_entry_updates_#{action_name}", :scientific_name => @scientific_name,
          :hierarchy_provider => @selected_hierarchy_entry.hierarchy_label)
    else
      @preferred_common_name ?
        I18n.t("meta_description_taxon_updates_#{action_name}_with_common_name", :scientific_name => @scientific_name,
          :preferred_common_name => @preferred_common_name) :
        I18n.t("meta_description_taxon_updates_#{action_name}", :scientific_name => @scientific_name)
    end
  end
  def additional_meta_keywords
   [ @preferred_common_name ?
      I18n.t("meta_keywords_taxon_updates_#{action_name}_with_common_name", :preferred_common_name => @preferred_common_name,
        :scientific_name => @scientific_name) :
      I18n.t("meta_keywords_taxon_updates_#{action_name}", :scientific_name => @scientific_name) ]
  end

end
