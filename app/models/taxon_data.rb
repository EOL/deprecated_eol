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
        row[:source] = row[:user]
      elsif row[:graph]
        row[:source] = TaxonData.graph_name_to_resource(row[:graph]).content_partner
      end
    end
    rows.delete_if{ |k,v| k[:attribute].blank? }
    rows = replace_licenses_with_mock_known_uris(rows)
    rows = add_known_uris_to_data(rows)
    rows.sort_by do |h|
      c = EOL::Sparql.uri_components(h[:attribute])
      c[:label].downcase
    end
  end

  def get_data_for_overview
    options = { :metadata => false }
    rows = association_data(options) + measurement_data(options)
    rows.delete_if{ |k,v| k[:attribute].blank? }
    rows = add_known_uris_to_data(rows)
    rows.sort_by do |h|
      c = EOL::Sparql.uri_components(h[:attribute])
      c[:label].downcase
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
    group_data_by_graph_and_uri(measurement_data + association_data)
  end

  def measurement_data(options = {})
    options.reverse_merge!({ :metadata => true })
    selects = "?attribute ?value ?unit_of_measure_uri"
    if options[:metadata]
      selects += "?data_point_uri ?graph ?attribution_predicate ?attribution_object ?occurrence_predicate ?occurrence_object ?event_predicate ?event_object"
    end
    query = "
      SELECT DISTINCT #{selects}
      WHERE {
        GRAPH ?resource_mappings_graph {
          ?taxon_id dwc:taxonConceptID <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}>
        } .
        GRAPH ?graph {
          ?data_point_uri a dwc:MeasurementOrFact
          { ?data_point_uri dwc:taxonConceptID <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}> }
          UNION
          { ?data_point_uri dwc:taxonID ?taxon_id } .
          ?data_point_uri dwc:measurementType ?attribute .
          ?data_point_uri dwc:measurementValue ?value .
          OPTIONAL {
            ?data_point_uri dwc:measurementUnit ?unit_of_measure_uri .
          }"
    if options[:metadata]
      query += ".
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
          }"
    end
    query += "
        }
      }"
    EOL::Sparql.connection.query(query)
  end

  def association_data(options = {})
    options.reverse_merge!({ :metadata => true })
    selects = "?attribute ?target_taxon_concept_id ?inverse_attribute"
    if options[:metadata]
      selects += "?data_point_uri ?value ?graph ?attribution_predicate ?attribution_object"
    end
    query = "
      SELECT DISTINCT #{selects}
      WHERE {
        GRAPH ?resource_mappings_graph {
          ?taxon_id dwc:taxonConceptID <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}> .
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
          }"
    if options[:metadata]
      query += ".
          OPTIONAL {
            ?data_point_uri ?attribution_predicate ?attribution_object
          }"
    end
    query += "
        } .
        OPTIONAL {
          GRAPH ?mappings {
            ?inverse_attribute owl:inverseOf ?attribute
          }
        }
      }"
    EOL::Sparql.connection.query(query)
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
      group_metadata_for('attribution', result, result_metadata)
      group_metadata_for('occurrence', result, result_metadata)
      group_metadata_for('event', result, result_metadata)
    end

    final_results = []
    grouped_data.each do |graph, graph_data|
      graph_data.each do |data_point_uri, data|
        final_results << { :graph => graph, :data_point_uri => data_point_uri }.merge(data)
      end
    end
    final_results
  end

  def group_metadata_for(prefix, result, result_metadata)
    predicate_key = (prefix + "_predicate").to_sym
    object_key = (prefix + "_object").to_sym
    if result[predicate_key] && result[object_key]
      if current_value_of_predicate = result_metadata[result[predicate_key]]
        if current_value_of_predicate.class == Array
          result_metadata[result[predicate_key]] << result[object_key]
        elsif current_value_of_predicate != result[object_key]
          result_metadata[result[predicate_key]] = [ current_value_of_predicate, result[object_key] ]
        end
      else
        result_metadata[result[predicate_key]] = result[object_key]
      end
    end
  end

  def add_known_uris_to_data(rows)
    known_uris = KnownUri.where(["uri in (?)", uris_in_data(rows)])
    rows.each do |row|
      replace_with_uri(row, :attribute, known_uris)
      replace_with_uri(row, :value, known_uris)
      replace_with_uri(row, :unit_of_measure_uri, known_uris)
      if taxon_id = KnownUri.taxon_concept_id(row[:value])
        row[:target_taxon_concept_id] = taxon_id
      end
      add_known_uris_to_metadata(row, known_uris) if row[:metadata]
    end
  end

  def add_known_uris_to_metadata(row, known_uris)
    # Don't modify hashes when you're iterating over them!
    delete_keys = []
    new_keys = {}
    row[:metadata].each do |key, val|
      key_uri = known_uris.find { |known_uri| known_uri.matches(key) }
      val_uri = known_uris.find { |known_uri| known_uri.matches(val) }
      row[:metadata][key] = val_uri if val_uri
      if key_uri
        new_keys[key_uri] = row[:metadata][key]
        delete_keys << key
      end
    end
    delete_keys.each { |k| row[:metadata].delete(k) }
    row[:metadata].merge!(new_keys)
  end

  def replace_with_uri(hash, key, known_uris)
    uri = known_uris.find { |known_uri| known_uri.matches(hash[key]) }
    hash[key] = uri if uri
  end

  # Licenses are special (NOTE we also cache them here on a per-page basis...):
  def replace_licenses_with_mock_known_uris(rows)
    rows.each do |row|
      row[:metadata].each do |key, val|
        if key == UserAddedDataMetadata::LICENSE_URI && license = License.find_by_source_url(val.to_s)
          row[:metadata][key] = KnownUri.new(:uri => val,
            :translations => [ TranslatedKnownUri.new(:name => license.title, :language => user.language) ])
        end
      end
    end
    rows
  end

  def uris_in_data(rows)
    uris  = rows.map { |row| row[:attribute] }.select { |attr| attr.is_a?(RDF::URI) }
    uris += rows.map { |row| row[:value] }.select { |attr| attr.is_a?(RDF::URI) }
    uris += rows.map { |row| row[:unit_of_measure_uri] }.select { |attr| attr.is_a?(RDF::URI) }
    uris += rows.map { |row| row[:metadata] ? row[:metadata].keys : nil }.flatten.compact.select { |attr| attr.is_a?(RDF::URI) }
    uris += rows.map { |row| row[:metadata] ? row[:metadata].values : nil }.flatten.compact.select { |attr| attr.is_a?(RDF::URI) }
    uris.map(&:to_s).uniq
  end

end
