#encoding: utf-8
# NOTE - I had to change a whole bunch of "NOT IN" clauses because they weren't working (SPARQL syntax error in my
# version.)  I think this will be fixed in later versions (it works for PL), but for now, this seems to work.
class TaxonData < TaxonUserClassificationFilter

  def self.graph_name_to_resource(graph_name)
    resource_id = graph_name.to_s.split("/").last
    Resource::find(resource_id)
  end

  # TODO - break down into friendlier syntax. :)
  def get_data
    rows = data
    rows.each do |row|
      if user_added_data = get_user_added_data(row[:data_point_uri])
        row[:user] = user_added_data.user
        row[:user_added_data] = user_added_data
      end
    end
  end

  private

  def get_user_added_data(value)
    if value && matches = value.to_s.match(UserAddedData::URI_REGEX)
      uad = UserAddedData.find(matches[1])
      return uad if uad
    end
    nil
  end

  def data
    group_data_by_graph_and_uri(single_point_data + dataset_data + associations_data)
  end

  def single_point_data
    EOL::Sparql.connection.query("
      SELECT DISTINCT ?graph ?data_point_uri ?attribute ?value ?attribution_predicate ?attribution_object ?occurrence_predicate ?occurrence_object ?event_predicate ?event_object
      WHERE {
        GRAPH ?resource_mappings_graph {
          ?taxon_id dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept.id}>
        } .
        GRAPH ?graph {
          ?data_point_uri a dwc:MeasurementOrFact
          { ?data_point_uri dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept.id}> }
          UNION
          { ?data_point_uri dwc:taxonID ?taxon_id } .
          ?data_point_uri dwc:measurementType ?attribute .
          ?data_point_uri dwc:measurementValue ?value .
          OPTIONAL {
            ?data_point_uri ?attribution_predicate ?attribution_object .
            FILTER (?attribution_predicate NOT IN (dwc:taxonConceptID, dwc:taxonID, dwc:occurrenceID))
          }
          OPTIONAL {
            ?data_point_uri dwc:occurrenceID ?occurrence .
            ?occurrence ?occurrence_predicate ?occurrence_object .
            FILTER (?occurrence_predicate NOT IN (rdf:type, dwc:taxonConceptID, dwc:taxonID, dwc:occurrenceID, dwc:eventID)) .
            OPTIONAL {
              ?occurrence dwc:eventID ?event .
              ?event ?event_predicate ?event_object .
              FILTER (?event_predicate NOT IN (rdf:type, dwc:taxonConceptID, dwc:taxonID, dwc:occurrenceID, dwc:eventID))
            }
          }
        }
      }
      ORDER BY ?attribute")
  end

  def associations_data
    EOL::Sparql.connection.query("
      SELECT DISTINCT ?graph ?data_point_uri ?attribute ?value ?attribution_predicate ?attribution_object ?target_taxon_concept_id ?inverse_attribute
      WHERE {
        GRAPH ?resource_mappings_graph {
          ?taxon_id dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept.id}> .
          ?value dwc:taxonConceptID ?target_taxon_concept_id
        } .
        GRAPH ?graph {
          ?data_point_uri a <http://eol.org/schema/Association> .
          {
            ?data_point_uri dwc:taxonID ?taxon_id .
            ?data_point_uri <http://eol.org/schema/targetTaxonID> ?value .
            ?data_point_uri <http://eol.org/schema/associationType> ?attribute
          }
          UNION
          {
            ?data_point_uri dwc:taxonID ?value .
            ?data_point_uri <http://eol.org/schema/targetTaxonID> ?taxon_id .
            ?data_point_uri <http://eol.org/schema/associationType> ?inverse_attribute
          } .
          OPTIONAL {
            ?data_point_uri ?attribution_predicate ?attribution_object
          }
        } .
        OPTIONAL {
          GRAPH ?mappings {
            ?inverse_attribute owl:inverseOf ?attribute
          }
        }
      }
      ORDER BY ?attribute")
  end

  def dataset_data
    EOL::Sparql.connection.query("
      SELECT DISTINCT ?graph ?data_point_uri ?attribute ?value ?attribution_predicate ?attribution_object
      WHERE {
        GRAPH ?resource_mappings_graph {
          ?taxon dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept.id}> .
        } .
        GRAPH ?graph {
          ?dataset a eol:DataSet .
          ?dataset dwc:taxonID ?taxon .
          OPTIONAL {
            ?dataset ?attribution_predicate ?attribution_object .
            FILTER (?attribution_predicate NOT IN (rdf:type, dwc:taxonID))
          } .
          ?data_point_uri a eol:DataPoint .
          ?data_point_uri eol:inDataSet ?dataset .
          ?data_point_uri dwc:measurementType ?attribute .
          ?data_point_uri dwc:measurementValue ?value
          FILTER (?attribute NOT IN (dwc:taxonID, dwc:eventID, dwc:occurrenceID))
        }
      }
      ORDER BY ?attribute")
  end

  # ?graph ?data_point_uri ?attribute ?value ?attribution_predicate ?attribution_object ?occurrence_predicate ?occurrence_object
  def group_data_by_graph_and_uri(sparql_results)
    grouped_data = {}
    sparql_results.each do |result|
      grouped_data[result[:graph]] ||= {}
      grouped_data[result[:graph]][result[:data_point_uri]] ||= {}
      result_data = grouped_data[result[:graph]][result[:data_point_uri]]
      result.each do |key, value|
        unless [ :attribution_predicate, :attribution_object ].include?(key)
          result_data[key] = value
        end
      end

      grouped_data[result[:graph]][result[:data_point_uri]][:metadata] ||= {}
      result_metadata = grouped_data[result[:graph]][result[:data_point_uri]][:metadata]
      if result[:attribution_predicate] && result[:attribution_object]
        if current_value_of_predicate = result_metadata[result[:attribution_predicate]]
          if current_value_of_predicate.class == Array
            result_metadata[result[:attribution_predicate]] << result[:attribution_object]
          elsif current_value_of_predicate != result[:attribution_object]
            result_metadata[result[:attribution_predicate]] = [ current_value_of_predicate, result[:attribution_object] ]
          end
        else
          result_metadata[result[:attribution_predicate]] = result[:attribution_object]
        end
      end
      if result[:occurrence_predicate] && result[:occurrence_object]
        if current_value_of_predicate = result_metadata[result[:occurrence_predicate]]
          if current_value_of_predicate.class == Array
            result_metadata[result[:occurrence_predicate]] << result[:occurrence_object]
          elsif current_value_of_predicate != result[:occurrence_object]
            result_metadata[result[:occurrence_predicate]] = [ current_value_of_predicate, result[:occurrence_object] ]
          end
        else
          result_metadata[result[:occurrence_predicate]] = result[:occurrence_object]
        end
      end
      if result[:event_predicate] && result[:event_object]
        if current_value_of_predicate = result_metadata[result[:event_predicate]]
          if current_value_of_predicate.class == Array
            result_metadata[result[:event_predicate]] << result[:event_object]
          elsif current_value_of_predicate != result[:event_object]
            result_metadata[result[:event_predicate]] = [ current_value_of_predicate, result[:event_object] ]
          end
        else
          result_metadata[result[:event_predicate]] = result[:event_object]
        end
      end
    end

    final_results = []
    grouped_data.each do |graph, graph_data|
      graph_data.each do |data_point_uri, data|
        final_results << { :graph => graph, :data_point_uri => data_point_uri }.merge(data)
      end
    end
    final_results
  end
end
