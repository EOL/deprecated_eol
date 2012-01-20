class Taxa::CommunitiesController < TaxaController

  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry, :update_user_content_level

  def index
    @communities = @taxon_concept.communities
    @assistive_section_header = I18n.t(:assistive_taxon_community_header)
    current_user.log_activity(:viewed_taxon_concept_community_communities, :taxon_concept_id => @taxon_concept.id)
  end

  def collections
    @collections = @taxon_concept.collections.select{ |c| c.published? && !c.watch_collection? }
    @assistive_section_header = I18n.t(:assistive_taxon_community_header)
    current_user.log_activity(:viewed_taxon_concept_community_collections, :taxon_concept_id => @taxon_concept.id)
  end

  def curators
    @curators = @taxon_concept.data_object_curators
    @assistive_section_header = I18n.t(:assistive_taxon_community_header)
    current_user.log_activity(:viewed_taxon_concept_community_curators, :taxon_concept_id => @taxon_concept.id)
  end

protected
  def set_meta_title
    I18n.t(:meta_title_template,
      :page_title => [
        @preferred_common_name ? I18n.t(:meta_title_taxon_communities_with_common_name,
        :preferred_common_name => @preferred_common_name, :scientific_name => @scientific_name) :
        I18n.t(:meta_title_taxon_communities, :scientific_name => @scientific_name),
        @assistive_section_header,
        @selected_hierarchy_entry ? @selected_hierarchy_entry.hierarchy_label : nil,
      ].compact.join(" - "))
  end
  def set_meta_description
    if @selected_hierarchy_entry
      @preferred_common_name ?
        I18n.t(:meta_description_hierarchy_entry_communities_with_common_name, :scientific_name => @scientific_name,
          :hierarchy_provider => @selected_hierarchy_entry.hierarchy_label,
          :preferred_common_name => @preferred_common_name) :
        I18n.t(:meta_description_hierarchy_entry_communities, :scientific_name => @scientific_name,
          :hierarchy_provider => @selected_hierarchy_entry.hierarchy_label)
    else
      @preferred_common_name ?
        I18n.t(:meta_description_taxon_communities_with_common_name, :scientific_name => @scientific_name,
          :preferred_common_name => @preferred_common_name) :
        I18n.t(:meta_description_taxon_communities, :scientific_name => @scientific_name)
    end
  end
  def additional_meta_keywords
   [ @preferred_common_name ?
      I18n.t(:meta_keywords_taxon_communities_with_common_name, :preferred_common_name => @preferred_common_name,
        :scientific_name => @scientific_name) :
      I18n.t(:meta_keywords_taxon_communities, :scientific_name => @scientific_name) ]
  end
end
