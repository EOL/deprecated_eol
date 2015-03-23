namespace :load_graphs_into_data_point_uris do
  desc "load trait data into_data_point_uris"
  task :load_trait_data => :environment do
     TaxonConcept.published.find_each do |taxon_concept|
      load_trait_data(taxon_concept)
    end
  end
  
  def load_trait_data(taxon_concept)
    virtuoso_results = raw_data(taxon_concept)
    KnownUri.add_to_data(virtuoso_results)
    preload_data_point_uris!(virtuoso_results, taxon_concept.try(:id))
  end
  
  def raw_data(taxon_concept)
    (measurement_data(taxon_concept) + association_data(taxon_concept)).delete_if { |k,v| k[:attribute].blank? }
  end

  def measurement_data(taxon_concept)
    query = "
      SELECT DISTINCT ?attribute ?value ?unit_of_measure_uri
        ?statistical_method ?life_stage ?sex ?data_point_uri ?graph
        ?taxon_concept_id
      WHERE {
        GRAPH ?graph {
          ?data_point_uri dwc:measurementType ?attribute .
          ?data_point_uri dwc:measurementValue ?value .
          OPTIONAL { ?data_point_uri dwc:measurementUnit ?unit_of_measure_uri } .
          OPTIONAL { ?data_point_uri eolterms:statisticalMethod ?statistical_method } .
        } .
        {
          ?data_point_uri dwc:taxonConceptID ?taxon_concept_id .
          FILTER( ?taxon_concept_id = <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}>)
          FILTER( ?graph != <#{Rails.configuration.user_added_data_graph}>)
          OPTIONAL { ?data_point_uri dwc:lifeStage ?life_stage } .
          OPTIONAL { ?data_point_uri dwc:sex ?sex }
        }
        UNION {
          ?data_point_uri dwc:occurrenceID ?occurrence .
          ?occurrence dwc:taxonID ?taxon .
          ?data_point_uri eol:measurementOfTaxon eolterms:true .
          GRAPH ?resource_mappings_graph {
            ?taxon dwc:taxonConceptID ?taxon_concept_id .
            FILTER( ?taxon_concept_id = <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}>)
          }
          OPTIONAL { ?occurrence dwc:lifeStage ?life_stage } .
          OPTIONAL { ?occurrence dwc:sex ?sex }
        }
      }
      "
    EOL::Sparql.connection.query(query)
  end
  
  def association_data(taxon_concept)
    query = "
      SELECT DISTINCT ?attribute ?value ?target_taxon_concept_id
        ?inverse_attribute ?data_point_uri ?graph
      WHERE {
        GRAPH ?resource_mappings_graph {
          ?taxon dwc:taxonConceptID ?source_taxon_concept_id .
          FILTER(?source_taxon_concept_id = <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}>) .
          ?value dwc:taxonConceptID ?target_taxon_concept_id
        } .
        GRAPH ?graph {
          ?occurrence dwc:taxonID ?taxon .
          ?target_occurrence dwc:taxonID ?value .
          {
            ?data_point_uri dwc:occurrenceID ?occurrence .
            ?data_point_uri eol:targetOccurrenceID ?target_occurrence .
            ?data_point_uri eol:associationType ?attribute
          }
          UNION
          {
            ?data_point_uri dwc:occurrenceID ?target_occurrence .
            ?data_point_uri eol:targetOccurrenceID ?occurrence .
            ?data_point_uri eol:associationType ?inverse_attribute
          }
          FILTER( ?graph != <#{Rails.configuration.user_added_data_graph}>)
        } .
        OPTIONAL {
          GRAPH ?mappings {
            ?inverse_attribute owl:inverseOf ?attribute
          }
        }
      }"
    EOL::Sparql.connection.query(query)
  end
  
  def preload_data_point_uris!(results, taxon_concept_id = nil)
    ActiveRecord::Base.transaction do
      partner_data = results.select{ |d| d.has_key?(:data_point_uri) }
      data_point_uris = DataPointUri.find_all_by_uri(partner_data.collect{ |d| d[:data_point_uri].to_s }.compact.uniq)
      partner_data.each do |row|
        if data_point_uri = data_point_uris.detect{ |dp| dp.uri == row[:data_point_uri].to_s }
          row[:data_point_instance] = data_point_uri
        end
      row[:taxon_concept_id] ||= taxon_concept_id
      row[:data_point_instance] ||= DataPointUri.create_from_virtuoso_response(row)
      row[:data_point_instance].update_with_virtuoso_response(row)
      end
    end
  end
end