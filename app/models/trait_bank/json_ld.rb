# NOTE: jsonld is ALWAYS in English. Period. This is expected and normal.
class TraitBank::JsonLd
  # TODO: I feel like we could definitely use this elsewhere! :S
  PREFIXES = {
    dc: 'http://purl.org/dc/terms/',
    dwc: 'http://rs.tdwg.org/dwc/terms/',
    eol: 'http://eol.org/schema/',
    eolterms: 'http://eol.org/schema/terms/',
    rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
    gbif: 'http://rs.gbif.org/terms/1.0/',
    foaf: 'http://xmlns.com/foaf/0.1/'
  }

  def self.graph_traits(traits)
    graph = {}
    prefixes = {}
    PREFIXES.each { |k,v| prefixes[v] = "#{k}:" }
    traits.each do |trait|
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
      graph << trait_json
    end
    graph
  end

  def self.add_default_context(jsonld)
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
