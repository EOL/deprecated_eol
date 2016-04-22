class PageTraits < TraitSet

  attr_reader :id

  def self.cache_key(id)
    "trait_bank/pages/#{id}"
  end

  # e.g.: pt = PageTraits.new(328598)
  def initialize(id)
    @id = id
    @rdf = TraitBank.cache_query(PageTraits.cache_key(id)) do
      TraitBank.page_with_traits(id)
    end
    trait_uris = Set.new(@rdf.map { |trait| trait[:trait] })
    @points = DataPointUri.where(uri: trait_uris.to_a.map(&:to_s)).
      includes(:comments, :taxon_data_exemplars)
    uris = Set.new(@rdf.flat_map { |rdf|
      rdf.values.select { |v| EOL::Sparql.is_uri?(v.to_s) } })
    uris.delete_if { |uri| uri.to_s =~ TraitBank::SOURCE_RE }
    # TODO: associations. We need the names of those taxa.
    @glossary = KnownUri.where(uri: uris.to_a.map(&:to_s)).
      includes(toc_items: :translated_toc_items)
    page_ids = Set.new(@rdf.map { |rdf| rdf[:value].to_s =~
      TraitBank.taxon_re ? $2 : nil }.compact).to_a
    @taxa = TaxonConcept.map_supercedure(page_ids) unless page_ids.blank?
    traits = @rdf.group_by { |trait| trait[:trait] }
    @traits = traits.keys.map { |trait| Trait.new(traits[trait], self) }
    source_ids = Set.new(@traits.map { |trait| trait.source_id })
    source_ids.delete(nil) # It happens.
    @sources = Resource.where(id: source_ids.to_a).includes(:content_partner)
  end

  # NOTE: only used manually to fix problems with "Could not find a data point for [trait]"
  def pointless
    traits.select { |t| t.point.nil? }
  end

  def jsonld
    concept = TaxonConcept.with_titles.find(@id)
    jsonld = { '@graph' => [ concept.to_jsonld ] }
    if wikipedia_entry = concept.wikipedia_entry
      jsonld['@graph'] << wikipedia_entry.mapping_jsonld
    end
    concept.common_names.map do |tcn|
      jsonld['@graph'] << tcn.to_jsonld
    end
    jsonld['@graph'].merge(TraitBank::JsonLd.graph_traits(@traits))
    TraitBank::JsonLd.add_default_context(jsonld)
    # I'm not sure we were ever doing this "right". :\ TODO: is this even useful?
    @glossary.each do |uri|
      jsonld['@context'][uri.name] = uri.uri
    end
    jsonld
  end
end
