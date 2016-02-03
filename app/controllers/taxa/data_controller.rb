class Taxa::DataController < TaxaController

  helper DataSearchHelper # Because we include one of its partials.

  before_filter :is_data_available
  before_filter :instantiate_taxon_page, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :load_data, except: [:index]

  # GET /pages/:taxon_id/data/index
  def index
    @page_traits = PageTraits.new(@taxon_concept.id)
    @jsonld = @page_traits.jsonld
  end

  # GET /pages/:taxon_id/data/about
  def about
    @toc_id = 'about'
  end

  # GET /pages/:taxon_id/data/glossary
  def glossary
    load_glossary
    @toc_id = 'glossary'
  end

  # GET /pages/:taxon_id/data/ranges
  def ranges
    @toc_id = 'ranges'
  end

protected

  def meta_description
    translation_vars = scoped_variables_for_translations.dup
    if @taxon_data # For Ajaxy pages; will remove this when replaced.
      @taxon_data.topics
      translation_vars[:topics] = @taxon_data.topics.join("; ") unless @taxon_data.topics.empty?
    elsif @page_traits && ! @page_traits.categories.blank?
      translation_vars[:topics] = @page_traits.categories.map { |c| c.label }.
        join("; ")
    end
    I18n.t("meta_description#{translation_vars[:topics] ? '_with_topics' : '_no_data'}", translation_vars)
  end

  def load_data
    raise "Data is temporarily disabled" unless EolConfig.data?
    EOL.log_call
    # Sad that we need to load all of this for the about and glossary tabs, but
    # TODO - we can cache this, later:
    @taxon_data = @taxon_page.data
    @range_data = @taxon_data.ranges_of_values
    @data_point_uris = @taxon_page.data.get_data
    @categories = TocItem.for_uris(current_language).
      select { |toc| @taxon_data.categories.include?(toc) }
    @include_other_category = @data_point_uris &&
      @data_point_uris.detect { |d| d.predicate_known_uri.nil? ||
        d.predicate_known_uri.toc_items.blank? }
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

  def is_data_available
    raise "TraitBank temporarily unavailable" unless EolConfig.data?
  end
end
