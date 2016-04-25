# NOTE: jsonld is ALWAYS in English. Period. This is expected and normal.
class TraitBank::JsonLd
  # TODO: I feel like we could definitely use this elsewhere! :S
  PREFIXES = {
    "http://purl.org/dc/terms/" => "dc:",
    "http://rs.tdwg.org/dwc/terms/" => "dwc:",
    "http://eol.org/schema/" => "eol:",
    "http://eol.org/schema/terms/" => "eolterms:",
    "http://www.w3.org/2000/01/rdf-schema#" => "rdfs:",
    "http://rs.gbif.org/terms/1.0/" => "gbif:",
    "http://xmlns.com/foaf/0.1/" => "foaf:"
  }

  PLATFORMS = [ "http://schema.org/DesktopWebPlatform",
    "http://schema.org/IOSPlatform",
    "http://schema.org/AndroidPlatform" ]

  class << self
    def target(action_type, target_type, url)
      { "@type" => action_type,
        "target" => { "@type": target_type,
                      "url" => url,
                      "actionPlatform" => PLATFORMS } }
    end

    def data_feed_item(concept_id, traits)
      concept = TaxonConcept.with_titles.find(concept_id)
      { "@type" => "DataFeedItem",
        "dateModified" => Time.now,
        "item" => for_concept(concept, traits) }
    end

    # NOTE: We look for an ITIS entry first, because it is the most robust,
    # detailed, and stable option. WHEN YOU CHANGE THIS (i.e.: when we get the
    # so-called "Dynamic EOL Hierarchy"), please let Google know that you've done
    # so: they will need to reindex things.
    def for_concept(concept)
      stable_entry = concept.entry(Hierarchy.itis)
      feed = {
        "@id" => concept.id,
        "@type" => "dwc:Taxon",
        "scientificName" => stable_entry.name.string,
        "dwc:taxonRank" => (stable_entry.rank) ? stable_entry.rank.label : nil }
      if parent = stable_entry.parent
        feed["dwc:parentNameUsageID"] =
          KnownUri.taxon_uri(parent.taxon_concept_id)
      end
      feed["potentialAction"] =
        target("EntryPoint", "Related", "http://eol.org/pages/#{concept.id}")
      if wikipedia_entry = concept.wikipedia_entry
        feed["sameAs"] = wikipedia_entry.outlink_url
      end
      feed["vernacularNames"] =
        concept.common_names.map { |tcn| tcn.to_json_hash }
      traits ||= PageTraits.new(self[:page_id]).traits
      feed["traits"] = traits.map { |trait| for_trait(trait) }
      feed
    end

    def for_trait(trait)
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
        PREFIXES.each { |r,v| predicate.sub!(r,v) }
        trait_json[predicate] = rdf[:value].to_s
      end
      # Associations need a _little_ tweaking:
      if trait.association?
        trait_json["eol:associationType"] =
          trait_json.delete("dwc:measurementType")
        trait_json["eol:targetTaxonID"] = trait.value_name
      end
      trait_json
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
      PREFIXES.each do |val, pre|
        jsonld['@context'][pre.chop] = val
      end
      jsonld
    end
  end
end
