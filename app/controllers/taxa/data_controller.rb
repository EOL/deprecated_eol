class Taxa::DataController < TaxaController

  before_filter :restrict_to_data_viewers
  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :load_data
  before_filter :load_glossary
  before_filter :add_page_view_log_entry

  def index
    @assistive_section_header = I18n.t(:assistive_data_header)
    @recently_used = KnownUri.where(['uri IN (?)', session[:rec_uris]]) if session[:rec_uris]
    @selected_data_point_uri_id = params.delete(:data_point_uri_id)
    @toc_id = params[:toc_id]
    @toc_id = nil unless @toc_id == 'other' || @categories.detect{ |toc| toc.id.to_s == @toc_id }
    current_user.log_activity(:viewed_taxon_concept_data, taxon_concept_id: @taxon_concept.id)
    respond_to do |format|
      format.html {}
      format.csv { render @taxon_data.to_csv }
    end
  end

  def about
  end

  def glossary
  end

protected

  def meta_description
    @taxon_data.topics
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:topics] = @taxon_data.topics.join("; ") unless @taxon_data.topics.empty?
    I18n.t("meta_description#{translation_vars[:topics] ? '_with_topics' : '_no_data'}", translation_vars)
  end

  def load_data
    # Sad that we need to load all of this for the about and glossary tabs, but TODO - we can cache this, later:
    @taxon_data = @taxon_page.data
    @data_point_uris = @taxon_page.data.get_data
    @categories = TocItem.for_uris(current_language).select{ |toc| @taxon_data.categories.include?(toc) }
  end

  def load_glossary
    @glossary_terms = @data_point_uris ?
      ( @data_point_uris.select{ |dp| ! dp.predicate_known_uri.blank? }.collect(&:predicate_known_uri) +
        @data_point_uris.select{ |dp| ! dp.object_known_uri.blank? }.collect(&:object_known_uri) +
        @data_point_uris.select{ |dp| ! dp.unit_of_measure_known_uri.blank? }.collect(&:unit_of_measure_known_uri)).compact.uniq
      : nil
  end

end
