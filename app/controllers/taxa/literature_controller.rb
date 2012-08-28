class Taxa::LiteratureController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry, :literature_links_contents

  def show
    @references = Ref.find_refs_for(@taxon_concept.id)
    @references = Ref.sort_by_full_reference(@references)
    @assistive_section_header = I18n.t(:assistive_literature_header)
    @rel_canonical_href = @selected_hierarchy_entry ?
      taxon_hierarchy_entry_literature_url(@taxon_concept, @selected_hierarchy_entry) :
      taxon_literature_url(@taxon_concept)
    current_user.log_activity(:viewed_taxon_concept_literature, :taxon_concept_id => @taxon_concept.id)
  end

  def bhl
    @assistive_section_header = I18n.t(:assistive_literature_header)
    @sort = params[:sort_by]
    @page = params[:page]
    @sort = 'year' unless ['title', 'title_desc', 'year', 'year_desc'].include?(@sort)
    @bhl_results = EOL::Solr::BHL.search(@taxon_concept, :sort => @sort, :page => @page)

    if @selected_hierarchy_entry
      @rel_canonical_href = bhl_taxon_hierarchy_entry_literature_url(@taxon_concept, @selected_hierarchy_entry,
        :page => rel_canonical_href_page_number(@bhl_results[:results]))
      @rel_prev_href = rel_prev_href_params(@bhl_results[:results]) ? bhl_taxon_hierarchy_entry_literature_url(@rel_prev_href_params) : nil
      @rel_next_href = rel_next_href_params(@bhl_results[:results]) ? bhl_taxon_hierarchy_entry_literature_url(@rel_next_href_params) : nil
    else
      @rel_canonical_href = bhl_taxon_literature_url(@taxon_concept, :page => rel_canonical_href_page_number(@bhl_results[:results]))
      @rel_prev_href = rel_prev_href_params(@bhl_results[:results]) ? bhl_taxon_literature_url(@rel_prev_href_params) : nil
      @rel_next_href = rel_next_href_params(@bhl_results[:results]) ? bhl_taxon_literature_url(@rel_next_href_params) : nil
    end

    current_user.log_activity(:viewed_taxon_concept_literature, :taxon_concept_id => @taxon_concept.id)
  end

  def bhl_title
    @title_item_id = params[:title_item_id]
    unless @title_item_id && @title_item_id.is_numeric?
      redirect_to bhl_taxon_literature_path(@taxon_concept)
    end
    @assistive_section_header = I18n.t(:assistive_literature_header)
    @bhl_title_results = EOL::Solr::BHL.search_publication(@taxon_concept, @title_item_id)
    # TODO: user natural sort to sort numerically, also romain numerals... not by string

    @rel_canonical_href = @selected_hierarchy_entry ?
      entry_bhl_title_url(@taxon_concept, @selected_hierarchy_entry, @title_item_id) :
      bhl_title_url(@taxon_concept, @title_item_id)

    current_user.log_activity(:viewed_taxon_concept_bhl_title, :taxon_concept_id => @taxon_concept.id)
  end

  def literature_links
    @assistive_section_header = I18n.t(:literature_links)
    @add_article_toc_id = nil
    @add_link_type_id = LinkType.paper ? LinkType.paper.id : nil
    @rel_canonical_href = @selected_hierarchy_entry ?
      literature_links_taxon_hierarchy_entry_literature_url(@taxon_concept, @selected_hierarchy_entry) :
      literature_links_taxon_literature_url(@taxon_concept)
    # current_user.log_activity(:viewed_taxon_concept_literature_links, :taxon_concept_id => @taxon_concept.id)
  end
  
  def literature_links_contents
    @literature_links_contents ||= @taxon_concept.text_for_user(current_user, {
      :language_ids => [ current_language.id ],
      :link_type_ids => [ LinkType.paper.id ] })
  end

end
