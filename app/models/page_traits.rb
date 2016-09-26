class PageTraits < TraitSet
  def self.cache_key(id)
    "trait_bank/pages/#{id}"
  end

  def self.cache_keys(id)
    base_key = cache_key(id)
    [base_key, "#{base_key}/trait_uris", "#{base_key}/uris",
      "#{base_key}/page_ids"]
  end

  def self.delete_caches(id)
    cache_keys.each { |key| Rails.cache.delete(key) }
  end

  # e.g.: pt = PageTraits.new(328598)
  def initialize(id)
    @id = id
    @populated = false
  end

  def populate
    return if @populated
    base_key = PageTraits.cache_key(@id)
    EOL.log(PageTraits.cache_keys(@id).join(", "), "K")
    @rdf = TraitBank.cache_query(base_key) do
      TraitBank.page_with_traits(@id)
    end
    trait_uris = TraitBank.cache_query("#{base_key}/trait_uris") do
      @rdf.map { |trait| trait[:trait] }.uniq.map(&:to_s)
    end
    @points = DataPointUri.where(uri: trait_uris).
      includes(:comments, :taxon_data_exemplars)
    uris = TraitBank.cache_query("#{base_key}/uris") do
      @rdf.flat_map do |rdf|
        rdf.values.select { |v| EOL::Sparql.is_uri?(v.to_s) }
      end.delete_if { |uri| uri.to_s =~ TraitBank::SOURCE_RE }.
        map(&:to_s)
    end
    @glossary = KnownUri.where(uri: uris).
      includes(toc_items: :translated_toc_items)
    page_ids = TraitBank.cache_query("#{base_key}/page_ids") do
      @rdf.map { |rdf| rdf[:value].to_s =~ TraitBank.taxon_re ? $2 : nil }.
        compact.uniq
    end
    @taxa = TaxonConcept.map_supercedure(page_ids) unless page_ids.blank?
    traits = @rdf.group_by { |trait| trait[:trait] }
    @traits = traits.keys.map { |trait| Trait.new(traits[trait], self) }
    source_ids = @traits.map { |trait| trait.source_id }.compact.uniq
    @sources = Resource.where(id: source_ids).includes(:content_partner)
    @populated = true
  end

  # NOTE: only used manually to fix problems with "Could not find a data point for [trait]"
  def pointless
    populate
    traits.select { |t| t.point.nil? }
  end

  def jsonld
    populate
    TraitBank::JsonLd.for_page(@id, self)
  end

  # Avoid a ton of output in the console:
  def to_s
    populate
    "<PageTraits @id=#{id} @rdf=(#{@rdf.size}xTriple) "\
      "@points=(#{@points.size}xDataPointUri) "\
      "@glossary=(#{@glossary.size}xKnownUri) "\
      "@taxa=#{@taxa.nil? ? "nil" : "(#{@taxa.size}xTaxonConcept)"} "\
      "@traits=(#{@traits.size}xTrait) @sources=(#{@sources.size}xResource)>"
  end
end
