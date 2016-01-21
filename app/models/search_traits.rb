class SearchTraits < TraitSet
  attr_accessor :pages

  # e.g.: @traits = SearchTraits.new(attribute: "http://purl.obolibrary.org/obo/OBA_0000056")

  # search_options = { querystring: @querystring, attribute: @attribute,
    # min_value: @min_value, max_value: @max_value, page: @page,
    # offset: @offset, unit: @unit, sort: @sort, language: current_language,
    # taxon_concept: @taxon_concept,
    # required_equivalent_attributes: @required_equivalent_attributes,
    # required_equivalent_values: @required_equivalent_values }
  def initialize(search_options)
    @rdf = []
    @pages = []
    @points = []
    @glossary = []
    @traits = []
    @sources = []
    unless search_options[:attribute].blank?
      # TODO: some of this could be generalized into TraitSet.
      @rdf = TraitBank::Scan.for(search_options)
      @pages = get_pages(@rdf.map { |trait| trait[:page].to_s })
      trait_uris = Set.new(@rdf.map { |trait| trait[:trait] })
      @points = DataPointUri.where(uri: trait_uris.to_a.map(&:to_s)).
        includes(:comments, :taxon_data_exemplars)
      uris = Set.new(@rdf.flat_map { |trait| trait.values.select { |v| v.uri? } })
      uris << search_options[:attribute]
      # TODO: associations. We need the names of those taxa.
      @glossary = KnownUri.where(uri: uris.to_a.map(&:to_s)).
        includes(toc_items: :translated_toc_items)
      traits = @rdf.group_by { |trait| trait[:trait] }
      @traits = traits.keys.map do |trait|
        Trait.new(traits[trait], self, taxa: @pages,
          predicate: search_options[:attribute])
      end
      source_ids = Set.new(@traits.map { |trait| trait.source_id })
      source_ids.delete(nil) # Just in case.
      @sources = Resource.where(id: source_ids.to_a).includes(:content_partner)
    end
  end

  def get_pages(uris)
    ids = Set.new
    uris.each do |uri|
      if uri =~ TraitBank.taxon_re
        # NOTE: it stinks that we "know" that taxon_re puts the id in #2. :|
        ids << $2
      end
    end
  # TaxonConceptName Load (2.3ms)  SELECT `taxon_concept_names`.* FROM `taxon_concept_names` WHERE `taxon_concept_names`.`taxon_concept_id` =
    TaxonConcept.where(id: ids.to_a).with_titles
  end
end
