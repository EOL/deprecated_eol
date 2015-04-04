class Taxa::DataController < TaxaController

  helper DataSearchHelper # Because we include one of its partials.

  before_filter :instantiate_taxon_page, :redirect_if_superceded, :set_headers
  # NOTE: the order matters, here. TODO: remove... I think we can.
  before_filter :load_data, :load_glossary, execpt: :index

  # GET /pages/:taxon_id/data/index
  def index
    @trait_id = params.delete(:trait_id)
    @toc_id = params.delete(:toc_id)
    # TODO: jsonld. It's a bear, and I want to wait for meta_traits.
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
    # Sad that we need to load all of this for the about and glossary tabs, but
    # TODO - we can cache this, later:
    @taxon_data = @taxon_page.data
    @range_data = @taxon_data.ranges_of_values
    @traits = @taxon_page.data.get_data
    # TODO: I don't believe we should store this in an instance var; it should
    # just be @taxon_data.categories.
    @categories = TocItem.for_uris(current_language).
      select { |toc| @taxon_data.categories.include?(toc) }
    # TODO: No need for this, handle it directly in the view. :|
    @include_other_category = @traits &&
      @traits.detect { |d| d.predicate_known_uri.nil? ||
        d.predicate_known_uri.toc_items.blank? }
    # TODO: I think we only need this for admins and master curators:
    @units_for_select = KnownUri.default_units_for_form_select
  end

  def load_glossary
    # TODO: HERE is where I think we should load KnownUris. ...Which means this
    # method should actually be gathering the IDs and then loading all the
    # KnownUris that match, not trying to get the KnownUris themselves, which we
    # would have had to load from six bajillion other places, potentially. Also,
    # I don't think a default value of [] is valid; if @traits is nil, this
    # should probably be nil, too.
    @glossary_terms = if @traits
      @traits.flat_map do |trait|
        [
          trait.try(:predicate_known_uri),
          trait.try(:object_known_uri),
          trait.try(:unit_of_measure_known_uri)
        ]
      end
    else
      []
    end
    @glossary_terms += @range_data.map { |r| r[:attribute] } if @range_data
    @glossary_terms.compact!.uniq!
  end

  def set_headers
    @assistive_section_header = I18n.t(:assistive_data_header)
  end
end
