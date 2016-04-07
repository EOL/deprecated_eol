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

  # TODO: this doesn't belong here; make a new class and pass self in. NOTE:
  # jsonld is ALWAYS in English. Period. This is expected and normal.
  def jsonld
    concept = TaxonConcept.find(@id)
    jsonld = { '@graph' => [ concept.to_jsonld ] }
    if wikipedia_entry = concept.wikipedia_entry
      jsonld['@graph'] << wikipedia_entry.mapping_jsonld
    end
    concept.common_names.map do |tcn|
      jsonld['@graph'] << tcn.to_jsonld
    end
    prefixes = {}
    PREFIXES.each { |k,v| prefixes[v] = "#{k}:" }
    @traits.each do |trait|
      # NOTE: this block was (mostly) stolen from DataPointUri#to_jsonld, and,
      # again, will replace it.
      trait_json = {
        "@id" => trait.uri.to_s,
        "@type" => trait.association? ? "eol:Association" : "dwc:MeasurementOrFact",
        "dwc:taxonID" => KnownUri.taxon_uri(@id),
        # These two are confusing, buuuuuut:
        "predicate" => trait.predicate_name,
        "dwc:measurementType" => trait.predicate,
        "value" => trait.value_name
      }
      if trait.units?
        trait_json[:units] = trait.units_name
      end
      if trait.point
        trait_json["data_point_uri_id"] = trait.point.id
      end
      trait.rdf.each do |rdf|
        predicate = rdf[:trait_predicate].dup.to_s
        # They don't care about the type we store it as...
        next if predicate == TraitBank.type_uri
        prefixes.each { |r,v| predicate.sub!(r,v) }
        trait_json[predicate] = rdf[:value].to_s
      end
      # Associations need a _little_ tweaking:
      if trait.association?
        trait_json["eol:associationType"] =
          trait_json.delete("dwc:measurementType")
        trait_json["eol:targetTaxonID"] = trait.value_name
      end
      jsonld["@graph"] << trait_json
    end
    add_default_context(jsonld)
    # I'm not sure we were ever doing this "right". :\ TODO: is this even useful?
    @glossary.each do |uri|
      jsonld['@context'][uri.name] = uri.uri
    end
    jsonld
  end

  def add_default_context(jsonld)
    # TODO: @context doesn't need all of these. Look through the @graph and
    # add things as needed based on the Sparql headers, then add the @ids.
    jsonld['@context'] = {
      'dwc:taxonID' => { '@type' => '@id' },
      'dwc:resourceID' => { '@type' => '@id' },
      'dwc:relatedResourceID' => { '@type' => '@id' },
      'dwc:relationshipOfResource' => { '@type' => '@id' },
      'dwc:vernacularName' => { '@container' => '@language' },
      'eol:associationType' => { '@type' => '@id' },
      'rdfs:label' => { '@container' => '@language' }
    }
    PREFIXES.each do |pre, val|
      jsonld['@context'][pre.to_s] = val
    end
    jsonld
  end
end
