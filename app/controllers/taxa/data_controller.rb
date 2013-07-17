class Taxa::DataController < TaxaController

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def index
    @assistive_section_header = I18n.t(:assistive_data_header)
    @recently_used = KnownUri.where(['uri IN (?)', session[:rec_uris]]) if session[:rec_uris]
    @taxon_data = @taxon_page.data
    @data = @taxon_data.get_data
    @toc_id = params[:toc_id]
    @selected_data_point_uri_id = params.delete(:data_point_uri_id)
    @show_download_data_button = ! @data.blank?
    @categories = TocItem.for_uris(current_language).select{ |toc| @taxon_data.categories.include?(toc) }
    @toc_id = nil unless @toc_id == 'other' || @categories.detect{ |toc| toc.id.to_s == @toc_id }
    current_user.log_activity(:viewed_taxon_concept_data, :taxon_concept_id => @taxon_concept.id)
  end

  def about
    # Sad that we need to load all of this, but TODO - we can cache this, later:
    @taxon_data = @taxon_page.data
    @data = @taxon_data.get_data
    @categories = TocItem.for_uris(current_language).select{ |toc| @taxon_data.categories.include?(toc) }
    @show_download_data_button = ! @categories.empty?
    respond_to do |format|
      format.html { }
      format.js { }
    end
  end

protected

  def meta_description
    topics = @data.map { |d| d[:attribute] }.select { |a| a.is_a?(KnownUri) }.uniq.compact.map(&:name)
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:topics] = topics.join("; ") unless topics.empty?
    I18n.t("meta_description#{translation_vars[:topics] ? '_with_topics' : '_no_data'}", translation_vars)
  end

end
