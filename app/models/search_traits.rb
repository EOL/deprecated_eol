class SearchTraits < TraitSet
  attr_accessor :pages

  # search_options = { querystring: @querystring, attribute: @attribute,
  #   min_value: @min_value, max_value: @max_value,
  #   unit: @unit, sort: @sort, language: current_language,
  #   taxon_concept: @taxon_concept,
  #   required_equivalent_attributes: @required_equivalent_attributes,
  #   required_equivalent_values: @required_equivalent_values }
  def initialize(search_options)
    # TODO: some of this could be generalized into TraitSet.
    @rdf = TraitBank::Search.for(search_options)
    @pages = get_pages(@rdf.map { |trait| trait[:page] })
    trait_uris = Set.new(@rdf.map { |trait| trait[:trait] })
    @points = DataPointUri.where(uri: trait_uris.to_a.map(&:to_s)).
      includes(:comments, :taxon_data_exemplars)
    uris = Set.new(@rdf.flat_map { |trait| trait.values.select { |v| v.uri? } })
    # TODO: associations. We need the names of those taxa.
    @glossary = KnownUri.where(uri: uris.to_a.map(&:to_s)).
      includes(toc_items: :translated_toc_items)
    traits = @rdf.group_by { |trait| trait[:trait] }
    @traits = traits.keys.map { |trait| Trait.new(traits[trait], self) }
    source_ids = Set.new(@traits.map { |trait| trait.source_id })
    source_ids.delete(nil) # Just in case.
    @sources = Resource.where(id: source_ids.to_a).includes(:content_partner)
  end

  def get_pages(uris)
    ids = Set.new
    uris.each do |uri|
      if uri =~ TraitBank.taxon_re
        # NOTE: it stinks that we "know" that taxon_re puts the id in #2. :|
        ids << $2
      end
    end
    # TODO: various convenient joins and includes and the like, I'm sure:
    TaxonConcept.where(id: ids)
  end
end
