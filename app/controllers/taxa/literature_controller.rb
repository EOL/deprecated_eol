class Taxa::LiteratureController < TaxaController
  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :literature_links_contents

  def show
    @references = Ref.find_refs_for(@taxon_concept.id)
    @references = Ref.sort_by_full_reference(@references)
    @assistive_section_header = I18n.t(:assistive_literature_header)
    @rel_canonical_href = taxon_literature_url(@taxon_page)
  end

  def bhl
    @assistive_section_header = I18n.t(:assistive_literature_header)
    @sort = params[:sort_by]
    @page = params[:page]
    @sort = 'year' unless ['title', 'title_desc', 'year', 'year_desc'].include?(@sort)
    @bhl_results = EOL::Solr::BHL.search(@taxon_concept, sort: @sort, page: @page)

    set_canonical_urls(for: @taxon_page, paginated: @bhl_results[:results],
                       url_method: :bhl_taxon_literature_url)
  end

  def bhl_title
    @title_item_id = params[:title_item_id]
    unless @title_item_id && @title_item_id.is_numeric?
      redirect_to bhl_taxon_literature_path(@taxon_concept)
    end
    @assistive_section_header = I18n.t(:assistive_literature_header)
    @bhl_title_results = EOL::Solr::BHL.search_publication(@taxon_concept, @title_item_id)
    # TODO: user natural sort to sort numerically, also romain numerals... not by string
    @rel_canonical_href = bhl_title_url(@taxon_page, @title_item_id)
  end

  def literature_links
    @assistive_section_header = I18n.t(:literature_links)
    @add_article_toc_id = nil
    @add_link_type_id = LinkType.paper ? LinkType.paper.id : nil
    @show_add_link_buttons = @add_link_type_id
    @rel_canonical_href = literature_links_taxon_literature_url(@taxon_page)
  end
  
  def literature_links_contents
    @literature_links_contents ||= @taxon_page.text(
      language_ids: [ current_language.id ],
      link_type_ids: [ LinkType.paper.id ]
    )
  end

end
