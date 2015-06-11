class Taxa::DetailsController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names

  # GET /pages/:taxon_id/details
  def index
    with_master_if_curator do
      @details = @taxon_page.details
    end
    @show_add_link_buttons = true
    @assistive_section_header = I18n.t(:assistive_details_header)
    @rel_canonical_href = taxon_details_url(@taxon_page)
  end

  # TODO - this doesn't belong here.
  def set_article_as_exemplar
    unless current_user && current_user.min_curator_level?(:assistant)
      
      raise EOL::Exceptions::SecurityViolation.new("User does not have set_article_as_exemplar privileges", :missing_set_article_as_exemplar_privilege)
      return
    end
    @taxon_concept = TaxonConcept.find(params[:taxon_id].to_i) rescue nil
    @data_object = DataObject.find_by_id(params[:data_object_id].to_i) rescue nil

    if @taxon_concept && @data_object
      TaxonConceptExemplarArticle.set_exemplar(@taxon_concept.id, @data_object.id)
      log_action(@taxon_concept, @data_object, :choose_exemplar_article)
    end

    store_location(params[:return_to] || request.referer)
    @taxon_concept.reload # This clears caches as well as any vars in memory.
    redirect_back_or_default taxon_details_path @taxon_concept.id
  end

protected
  def meta_description
    chapter_list = @details.chapter_list
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:chapter_list] = chapter_list.join("; ") unless chapter_list.blank?
    I18n.t("meta_description#{translation_vars[:preferred_common_name] ? '_with_common_name' :
           ''}#{translation_vars[:chapter_list] ? '_with_chapter_list' : '_no_data'}",
           translation_vars)
  end
  def meta_keywords
    keywords = super
    toc_subjects = @details.chapter_list.join(", ")
    [keywords, toc_subjects].compact.join(', ')
  end
  
end
