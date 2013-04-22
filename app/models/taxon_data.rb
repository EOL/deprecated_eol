#encoding: utf-8
# NOTE - I had to change a whole bunch of "NOT IN" clauses because they weren't working (SPARQL syntax error in my
# version.)  I think this will be fixed in later versions (it works for PL), but for now, this seems to work.
class TaxonData < TaxonUserClassificationFilter

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
    group_data_by_graph_and_uri(single_point_data + dataset_data) + flat_data
  end

  # NOTE - I changed the order of the two GRAPH clauses because the Q wasn't working for me as written. At all.
  # Syntax error.
  def flat_data
    EOL::Sparql.connection.query("
      SELECT DISTINCT ?graph ?taxon_uri ?attribute ?value
      WHERE {
        GRAPH ?graph {
          ?taxon_uri ?attribute ?value
          FILTER (?graph != <http://eol.org/taxon_mappings/> AND ?graph != <#{UserAddedData::GRAPH_NAME}>)
          FILTER ((?attribute != rdf:type) &&
                  (?attribute != eol:canonical))
        } .
        GRAPH <http://eol.org/taxon_mappings/> {
          ?taxon_uri dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept.id}> .
        }
      }
      ORDER BY ?attribute")
  end

  # TODO - gah!  Don't commit this.  I had to remove these lines to get things to work locally, without the
  # taxon_mappings data that PL has:
        #GRAPH <http://eol.org/taxon_mappings/> {
          #?taxon dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept.id}> .
        #} .
  def single_point_data
    EOL::Sparql.connection.query("
      SELECT DISTINCT ?graph ?data_point_uri ?attribute ?value ?attribution_predicate ?attribution_object
      WHERE {
        GRAPH ?graph {
          { ?data_point_uri dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept.id}> }
          UNION
          { ?data_point_uri dwc:taxonID ?taxon } .
          ?data_point_uri dwc:measurementType ?attribute .
          ?data_point_uri dwc:measurementValue ?value .
          OPTIONAL {
            ?data_point_uri ?attribution_predicate ?attribution_object .
            FILTER ((?attribution_predicate != rdf:type) &&
                    (?attribution_predicate != dwc:taxonConceptID) &&
                    (?attribution_predicate != dwc:measurementType) &&
                    (?attribution_predicate != dwc:measurementValue))
          } .
          FILTER (?graph != <http://eol.org/taxon_mappings/>)
          FILTER (?attribute != rdf:type)
        }
      }
      ORDER BY ?attribute")
  end

  def dataset_data
    EOL::Sparql.connection.query("
      SELECT DISTINCT ?graph ?data_point_uri ?attribute ?value ?attribution_predicate ?attribution_object
      WHERE {
        GRAPH <http://eol.org/taxon_mappings/> {
          ?taxon dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept.id}> .
        } .
        GRAPH ?graph {
          ?dataset a eol:DataSet .
          { ?dataset dwc:taxonConceptID <http://eol.org/pages/#{taxon_concept.id}> }
          UNION
          { ?dataset dwc:taxonID ?taxon } .
          OPTIONAL {
            ?dataset ?attribution_predicate ?attribution_object .
            FILTER ((?attribution_predicate != rdf:type) &&
                    (?attribution_predicate != dwc:taxonID))
          } .
          ?data_point_uri a eol:DataPoint .
          ?data_point_uri eol:inDataSet ?dataset .
          ?data_point_uri dwc:measurementType ?attribute .
          ?data_point_uri dwc:measurementValue ?value
        }
      }
      ORDER BY ?attribute")
  end

  # ?graph ?data_point_uri ?attribute ?value ?attribution_predicate ?attribution_object
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
