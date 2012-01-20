class Taxa::LiteratureController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    references
  end

  def references
    @assistive_section_header = I18n.t(:assistive_literature_header)
    @references = Ref.find_refs_for(@taxon_concept.id)
    @references = Ref.sort_by_full_reference(@references)
    current_user.log_activity(:viewed_taxon_concept_literature, :taxon_concept_id => @taxon_concept.id)
  end

  def bhl
    @assistive_section_header = I18n.t(:assistive_literature_header)
    @sort = params[:sort_by]
    @page = params[:page]
    @sort = 'year' unless ['title', 'title_desc', 'year', 'year_desc'].include?(@sort)
    @bhl_results = EOL::Solr::BHL.search(@taxon_concept, :sort => @sort, :page => @page)
    current_user.log_activity(:viewed_taxon_concept_literature, :taxon_concept_id => @taxon_concept.id)
  end

  def bhl_title
    @title_item_id = params[:title_item_id]
    unless @title_item_id && @title_item_id.is_numeric?
      redirect_to bhl_taxon_literature_path(@taxon_concept), :status => :moved_permanently
    end
    @assistive_section_header = I18n.t(:assistive_literature_header)
    @bhl_title_results = EOL::Solr::BHL.search_publication(@taxon_concept, @title_item_id)
    # TODO: user natural sort to sort numerically, also romain numerals... not by string
    current_user.log_activity(:viewed_taxon_concept_bhl_title, :taxon_concept_id => @taxon_concept.id)
  end

protected
  def set_meta_title
    I18n.t(:meta_title_template,
      :page_title => [
        @preferred_common_name ? I18n.t(:meta_title_taxon_maps_with_common_name,
        :preferred_common_name => @preferred_common_name, :scientific_name => @scientific_name) :
        I18n.t(:meta_title_taxon_literature, :scientific_name => @scientific_name),
        @assistive_section_header,
        @selected_hierarchy_entry ? @selected_hierarchy_entry.hierarchy_label : nil,
      ].compact.join(" - "))
  end
  def set_meta_description
    if @selected_hierarchy_entry
      @preferred_common_name ?
        I18n.t(:meta_description_hierarchy_entry_literature_with_common_name, :scientific_name => @scientific_name,
          :hierarchy_provider => @selected_hierarchy_entry.hierarchy_label,
          :preferred_common_name => @preferred_common_name) :
        I18n.t(:meta_description_hierarchy_entry_literature, :scientific_name => @scientific_name,
          :hierarchy_provider => @selected_hierarchy_entry.hierarchy_label)
    else
      @preferred_common_name ?
        I18n.t(:meta_description_taxon_literature_with_common_name, :scientific_name => @scientific_name,
          :preferred_common_name => @preferred_common_name) :
        I18n.t(:meta_description_taxon_literature, :scientific_name => @scientific_name)
    end
  end
  def additional_meta_keywords
   [ @preferred_common_name ?
      I18n.t(:meta_keywords_taxon_literature_with_common_name, :preferred_common_name => @preferred_common_name,
        :scientific_name => @scientific_name) :
      I18n.t(:meta_keywords_taxon_literature, :scientific_name => @scientific_name) ]
  end
end
