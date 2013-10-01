class Taxa::DataController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @assistive_section_header = I18n.t(:assistive_data_header)
    @recently_used = KnownUri.where(['uri IN (?)', session[:rec_uris]]) if session[:rec_uris]
    @taxon_data = @taxon_page.data
    @data_point_uris = @taxon_page.data.get_data
    @toc_id = params[:toc_id]
    @selected_data_point_uri_id = params.delete(:data_point_uri_id)
    @categories = TocItem.for_uris(current_language).select{ |toc| @taxon_data.categories.include?(toc) }
    @toc_id = nil unless @toc_id == 'other' || @categories.detect{ |toc| toc.id.to_s == @toc_id }
    @supress_disclaimer = true
    current_user.log_activity(:viewed_taxon_concept_data, :taxon_concept_id => @taxon_concept.id)
    debugger
    respond_to do |format|
      format.html {}
      format.csv { render @taxon_data.to_csv }
    end
  end

  def about
    # Sad that we need to load all of this, but TODO - we can cache this, later:
    @taxon_data = @taxon_page.data
    @data_point_uris = @taxon_page.data.get_data
    @categories = TocItem.for_uris(current_language).select{ |toc| @taxon_data.categories.include?(toc) }
    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

protected

  def meta_description
    @taxon_data.topics
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:topics] = @taxon_data.topics.join("; ") unless @taxon_data.topics.empty?
    I18n.t("meta_description#{translation_vars[:topics] ? '_with_topics' : '_no_data'}", translation_vars)
  end

end
