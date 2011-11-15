class Taxa::LiteratureController < TaxaController
  before_filter :instantiate_taxon_concept
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
      redirect_to bhl_taxon_literature_path(@taxon_concept)
    end
    @assistive_section_header = I18n.t(:assistive_literature_header)
    @bhl_title_results = EOL::Solr::BHL.search_publication(@taxon_concept, @title_item_id)
    # TODO: user natural sort to sort numerically, also romain numerals... not by string
    current_user.log_activity(:viewed_taxon_concept_bhl_title, :taxon_concept_id => @taxon_concept.id)
  end
end
