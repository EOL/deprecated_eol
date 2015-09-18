class Taxa::DataController < TaxaController

  helper DataSearchHelper # Because we include one of its partials.

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :load_data
  before_filter :load_glossary

  # GET /pages/:taxon_id/data/index
  def index
    EOL.log_call
    @assistive_section_header = I18n.t(:assistive_data_header)
    @recently_used = KnownUri.where(uri: session[:rec_uris]) if
      session[:rec_uris]
    @selected_data_point_uri_id = params.delete(:data_point_uri_id)
    if params[:toc_id].nil?
      @toc_id = 'ranges' if @data_point_uris.blank? && !@range_data.blank?
    else
      @toc_id = params[:toc_id]
      @toc_id = nil unless @toc_id == 'other' ||
        @categories.detect { |toc| toc.id.to_s == @toc_id }
    end

    @querystring = ''
    @sort = ''
    EOL.log("building jsonld")
    @jsonld = @taxon_data.jsonld
    EOL.log("#index done, rendering")
  end

  # GET /pages/:taxon_id/data/about
  def about
    @toc_id = 'about'
  end

  # GET /pages/:taxon_id/data/glossary
  def glossary
    @toc_id = 'glossary'
  end

  # GET /pages/:taxon_id/data/ranges
  def ranges
    @toc_id = 'ranges'
  end

protected

  def meta_description
    @taxon_data.topics
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:topics] = @taxon_data.topics.join("; ") unless @taxon_data.topics.empty?
    I18n.t("meta_description#{translation_vars[:topics] ? '_with_topics' : '_no_data'}", translation_vars)
  end

  def load_data
    EOL.log_call
    # Sad that we need to load all of this for the about and glossary tabs, but
    # TODO - we can cache this, later:
    @taxon_data = @taxon_page.data
    EOL.log("ranges_of_values", prefix: '.')
    @range_data = @taxon_data.ranges_of_values
    EOL.log("get_data", prefix: '.')
    @data_point_uris = @taxon_page.data.get_data
    EOL.log("for_uris", prefix: '.')
    @categories = TocItem.for_uris(current_language).
      select { |toc| @taxon_data.categories.include?(toc) }
    EOL.log("include_other_category", prefix: '.')
    @include_other_category = @data_point_uris &&
      @data_point_uris.detect { |d| d.predicate_known_uri.nil? ||
        d.predicate_known_uri.toc_items.blank? }
    EOL.log("default_units_for_form_select", prefix: '.')
    @units_for_select = KnownUri.default_units_for_form_select
  end

  def load_glossary
    @glossary_terms = @data_point_uris ?
      ( @data_point_uris.select{ |dp| ! dp.predicate_known_uri.blank? }.collect(&:predicate_known_uri) +
        @data_point_uris.select{ |dp| ! dp.object_known_uri.blank? }.collect(&:object_known_uri) +
        @data_point_uris.select{ |dp| ! dp.unit_of_measure_known_uri.blank? }.collect(&:unit_of_measure_known_uri) +
        @range_data.collect{ |r| r[:attribute] }).compact.uniq
      : []
  end

end
