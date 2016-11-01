class PageTraits < TraitSet
  def self.cache_key(id)
    "trait_bank/pages/#{id}"
  end

  def self.cache_keys(id)
    @base_key = cache_key(id)
    [@base_key, "#{@base_key}/trait_uris", "#{@base_key}/uris",
      "#{@base_key}/page_ids"]
  end

  def self.delete_caches(id)
    cache_keys(id).each { |key| Rails.cache.delete(key) }
  end

  # e.g.: pt = PageTraits.new(328598)
  def initialize(id)
    @id = id
    EOL.debug("calling PageTraits#initialize(#{id})")
    @populated = false
    @base_key = PageTraits.cache_key(@id)
  end

  def jsonld_key
    "#{@base_key}/jsonld"
  end

  def populate
    return if @populated
    EOL.log("BUILD TRAITS: to clear use PageTraits.delete_caches(#{@id})", prefix: "K")
    @rdf = TraitBank.cache_query(@base_key) do
      TraitBank.page_with_traits(@id)
    end
    trait_uris = TraitBank.cache_query("#{@base_key}/trait_uris") do
      @rdf.map { |trait| trait[:trait] }.uniq.map(&:to_s)
    end
    @points = DataPointUri.where(uri: trait_uris).
      includes(:taxon_data_exemplars)
    uris = TraitBank.cache_query("#{@base_key}/uris") do
      @rdf.flat_map do |rdf|
        rdf.values.select { |v| EOL::Sparql.is_uri?(v.to_s) }
      end.delete_if { |uri| uri.to_s =~ TraitBank::SOURCE_RE }.
        map(&:to_s)
    end
    @glossary = KnownUri.where(uri: uris).
      includes(toc_items: :translated_toc_items)
    @taxa = TraitBank.cache_query("#{@base_key}/taxa") do
      page_ids = @rdf.map { |rdf| rdf[:value].to_s =~ TraitBank.taxon_re ? $2 : nil }.
        compact.uniq
      if page_ids.blank?
        {}
      else
        TaxonConcept.map_supercedure(page_ids)
      end
    end
    traits = @rdf.group_by { |trait| trait[:trait] }
    @traits = traits.keys.map { |trait| Trait.new(traits[trait], self) }
    build_sources
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
