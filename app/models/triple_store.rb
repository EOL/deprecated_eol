# I was sick of seeing queries in the wrong place, so I'm gathering them here.
class TripleStore
  DEFAULT_PAGE_SIZE = 30
  MAXIMUM_DESCENDANTS_FOR_CLADE_SEARCH = 60000
  GGI_URIS = [
    'http://eol.org/schema/terms/NumberRichSpeciesPagesInEOL',
    'http://eol.org/schema/terms/NumberOfSequencesInGenBank',
    'http://eol.org/schema/terms/NumberRecordsInGBIF',
    'http://eol.org/schema/terms/NumberRecordsInBOLD',
    'http://eol.org/schema/terms/NumberPublicRecordsInBOLD',
    'http://eol.org/schema/terms/NumberSpecimensInGGBN',
    'http://eol.org/schema/terms/NumberReferencesInBHL' ]

  extend EOL::Sparql::SafeConnection

  class < self
    def search(options={})
      if_connection_fails_return(nil) do
        # only attribute is required, querystring may be left blank to get all
        # usages of an attribute TODO: remove this when we allow other searches!
        return [].paginate if options[:attribute].blank?
        options[:page] ||= 1
        options[:per_page] ||= DEFAULT_PAGE_SIZE
        options[:language] ||= Language.default
        total_results = EOL::Sparql.connection.query(
          EOL::Sparql::SearchQueryBuilder.
            prepare_search_query(options.merge(only_count: true))
        ).first[:count].to_i
        results = EOL::Sparql.connection.query(
          EOL::Sparql::SearchQueryBuilder.prepare_search_query(options)
        )
        # TODO - we should probably check for taxon supercedure, here.
        if options[:for_download]
          # when downloading, we don't the full TaxonDataSet which will want to
          # insert rows into MySQL for each Trait, which is very expensive when
          # downloading lots of rows TODO: I don't believe this is true, now
          # that it's a background process. fix.
          KnownUri.add_to_data(results)
          traits = results.collect do |row|
            trait = Trait.new(Trait.attributes_from_virtuoso_response(row))
            trait.convert_units
            trait
          end
          Trait.preload_associations(traits, { taxon_concept:
              [ { preferred_entry: { hierarchy_entry: { name: :ranked_canonical_form } } } ],
              resource: :content_partner },
            select: {
              taxon_concepts: [ :id, :supercedure_id ],
              hierarchy_entries: [ :id, :taxon_concept_id, :name_id ],
              names: [ :id, :string, :ranked_canonical_form_id ],
              canonical_forms: [ :id, :string ] }
            )
        else
          taxon_data_set = TaxonDataSet.new(results)
          traits = taxon_data_set.traits
          Trait.preload_associations(traits, :taxon_concept)
          # This next line is for catching a rare case, seen in development,
          # when the concept referred to by Virtuoso is not in the database
          traits.delete_if { |dp| dp.taxon_concept.nil? }
          TaxonConcept.preload_for_shared_summary(
            traits.collect(&:taxon_concept), language_id: options[:language].id
          )
        end
        TaxonConcept.load_common_names_in_bulk(traits.collect(&:taxon_concept),
          options[:language].id)
        WillPaginate::Collection.create(
          options[:page], options[:per_page], total_results
        ) do |pager|
          pager.replace(traits)
        end
      end
    end

    def measurement_data(taxon)
      EOL::Sparql.connection.query(
        "SELECT DISTINCT ?attribute ?value ?unit_of_measure_uri "\
        "  ?statistical_method ?life_stage ?sex ?trait ?graph "\
        "  ?taxon_concept_id "\
        "WHERE { "\
        "  GRAPH ?graph { "\
        "    ?trait dwc:measurementType ?attribute . "\
        "    ?trait dwc:measurementValue ?value . "\
        "    OPTIONAL { ?trait dwc:measurementUnit ?unit_of_measure_uri } . "\
        "    OPTIONAL { ?trait eolterms:statisticalMethod ?statistical_method } . "\
        "  } . "\
        "  { "\
        "    ?trait dwc:taxonConceptID ?taxon_concept_id . "\
        "    FILTER( ?taxon_concept_id = "\
        "      <#{UserAddedData::SUBJECT_PREFIX}#{taxon.id}>) "\
        "    OPTIONAL { ?trait dwc:lifeStage ?life_stage } . "\
        "    OPTIONAL { ?trait dwc:sex ?sex } "\
        "  } "\
        "  UNION { "\
        "    ?trait dwc:occurrenceID ?occurrence . "\
        "    ?occurrence dwc:taxonID ?taxon . "\
        "    ?trait eol:measurementOfTaxon eolterms:true . "\
        "    GRAPH ?resource_mappings_graph { "\
        "      ?taxon dwc:taxonConceptID ?taxon_concept_id . "\
        "      FILTER( ?taxon_concept_id = "\
        "        <#{UserAddedData::SUBJECT_PREFIX}#{taxon.id}>) "\
        "    } "\
        "    OPTIONAL { ?occurrence dwc:lifeStage ?life_stage } . "\
        "    OPTIONAL { ?occurrence dwc:sex ?sex } "\
        "  } "\
        "} "\
        "LIMIT 800")
    end

    def association_data(taxon)
      EOL::Sparql.connection.query(
        "SELECT DISTINCT ?attribute ?value ?target_taxon_concept_id "\
        "  ?inverse_attribute ?trait ?graph "\
        "WHERE { "\
        "  GRAPH ?resource_mappings_graph { "\
        "    ?taxon dwc:taxonConceptID ?source_taxon_concept_id . "\
        "    FILTER(?source_taxon_concept_id = "\
        "      <#{UserAddedData::SUBJECT_PREFIX}#{taxon.id}>) . "\
        "    ?value dwc:taxonConceptID ?target_taxon_concept_id "\
        "  } . "\
        "  GRAPH ?graph { "\
        "    ?occurrence dwc:taxonID ?taxon . "\
        "    ?target_occurrence dwc:taxonID ?value . "\
        "    { "\
        "      ?trait dwc:occurrenceID ?occurrence . "\
        "      ?trait eol:targetOccurrenceID ?target_occurrence . "\
        "      ?trait eol:associationType ?attribute "\
        "    } "\
        "    UNION "\
        "    { "\
        "      ?trait dwc:occurrenceID ?target_occurrence . "\
        "      ?trait eol:targetOccurrenceID ?occurrence . "\
        "      ?trait eol:associationType ?inverse_attribute "\
        "    } "\
        "  } . "\
        "  OPTIONAL { "\
        "    GRAPH ?mappings { "\
        "      ?inverse_attribute owl:inverseOf ?attribute "\
        "    } "\
        "  } "\
        "} "\
        "LIMIT 800")
    end

    def ranges(taxon)
      EOL::Sparql.connection.query(
        "SELECT ?attribute, ?measurementOfTaxon, "\
        "  COUNT(DISTINCT ?descendant_concept_id) as ?count_taxa, "\
        "  COUNT(DISTINCT ?trait) as ?count_measurements, "\
        "  MIN(xsd:float(?value)) as ?min, MAX(xsd:float(?value)) as ?max, "\
        "  ?unit_of_measure_uri "\
        "WHERE { "\
        "  ?parent_taxon dwc:taxonConceptID "\
        "    <#{UserAddedData::SUBJECT_PREFIX}#{taxon.id}> . "\
        "  ?t dwc:parentNameUsageID+ ?parent_taxon . "\
        "  ?t dwc:taxonConceptID ?descendant_concept_id . "\
        "  ?occurrence dwc:taxonID ?taxon . "\
        "  ?taxon dwc:taxonConceptID ?descendant_concept_id . "\
        "  ?trait dwc:occurrenceID ?occurrence . "\
        "  ?trait eol:measurementOfTaxon ?measurementOfTaxon . "\
        "  ?trait dwc:measurementType ?attribute . "\
        "  ?trait dwc:measurementValue ?value . "\
        "  OPTIONAL { "\
        "    ?trait dwc:measurementUnit ?unit_of_measure_uri "\
        "  } "\
        "  FILTER ( "\
        "    ?attribute IN ( "\
        "      IRI(<#{KnownUri.uris_for_clade_aggregation.join(">),IRI(<")}>) "\
        "    ) "\
        "  ) "\
        "} "\
        "GROUP BY ?attribute ?unit_of_measure_uri ?measurementOfTaxon "\
        "ORDER BY DESC(?min)"
      # TODO: Maybe we should add this as a filter to the query?!
      ).delete_if { |r| r[:measurementOfTaxon] != Rails.configuration.uri_true }
    end

    def iucn_data_objects(taxon)
      EOL::Sparql.connection.query(
        "SELECT DISTINCT ?attribute ?value ?trait ?graph ?taxon_concept_id"\
        "  WHERE {"\
        "    GRAPH ?graph {"\
        "      ?trait dwc:measurementType ?attribute ."\
        "      ?trait dwc:measurementValue ?value."\
        "      FILTER (?attribute = "\
        "        <http://rs.tdwg.org/ontology/voc/SPMInfoItems#ConservationStatus>)"\
        "    }."\
        "    {"\
        "      ?trait dwc:occurrenceID ?occurrence ."\
        "      ?occurrence dwc:taxonID ?taxon ."\
        "      ?taxon dwc:taxonConceptID ?taxon_concept_id ."\
        "      FILTER (?taxon_concept_id = "\
        "        <#{UserAddedData::SUBJECT_PREFIX}#{taxon.id}>)"\
        "    }"\
        "  }")
    end

    # we only need a set number of attributes for GGI, and we know there are no associations
    # so it is more efficient to have a custom query to gather these data. We might be able
    # to generalize this, for example if we return search results for multiple attributes
    def ggi(taxon)
      results = EOL::Sparql.connection.query(
        "SELECT DISTINCT ?attribute ?value ?trait ?graph ?taxon_concept_id "\
        "WHERE { "\
        "  GRAPH ?graph { "\
        "    ?trait dwc:measurementType ?attribute . "\
        "    ?trait dwc:measurementValue ?value . "\
        "    FILTER ( ?attribute IN (<#{GGI_URIS.join(">,<")}>)) "\
        "  } . "\
        "  { "\
        "    ?trait dwc:occurrenceID ?occurrence . "\
        "    ?occurrence dwc:taxonID ?taxon . "\
        "    ?trait eol:measurementOfTaxon eolterms:true . "\
        "    ?taxon dwc:taxonConceptID ?taxon_concept_id . "\
        "    FILTER ( ?taxon_concept_id = <#{UserAddedData::SUBJECT_PREFIX}#{taxon.id}>) . "\
        "  } "\
        "} "\
        "LIMIT 100"
      )
      results
    end
  end # class < self
end
