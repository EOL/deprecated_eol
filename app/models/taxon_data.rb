#encoding: utf-8
# NOTE - I had to change a whole bunch of "NOT IN" clauses because they weren't working (SPARQL syntax error in my
# version.)  I think this will be fixed in later versions (it works for PL), but for now, this seems to work.
class TaxonData < TaxonUserClassificationFilter

  MAX_EXEMPLAR_DATA = 5 # TODO - pick a number, move this to the DB or something.

  def self.graph_name_to_resource_id(graph_name)
    graph_name.to_s.split("/").last
  end

  def self.search(options={})
    return nil if options[:querystring].blank?
    options[:per_page] = 30
    total_results = EOL::Sparql.connection.query(prepare_search_query(options.merge(:only_count => true))).first[:count].to_i
    results = EOL::Sparql.connection.query(prepare_search_query(options))
    TaxonData.add_known_uris_to_data(results)
    WillPaginate::Collection.create(options[:page], options[:per_page], total_results) do |pager|
       pager.replace(results)
    end
  end

  def self.prepare_search_query(options={})
    if options[:only_count]
      query = "SELECT COUNT(*) as ?count"
    else
      query = "SELECT ?data_point_uri, ?attribute, ?value, ?taxon_concept_id, ?unit_of_measure_uri"
    end
    query += " WHERE {
        ?data_point_uri a <#{DataMeasurement::CLASS_URI}> .
        ?data_point_uri dwc:taxonID ?taxon_id .
        ?taxon_id dwc:taxonConceptID ?taxon_concept_id .
        ?data_point_uri dwc:measurementType ?attribute .
        ?data_point_uri dwc:measurementValue ?value .
        OPTIONAL {
          ?data_point_uri dwc:measurementUnit ?unit_of_measure_uri .
        } . "
    if options[:from] && options[:to]
      query += "FILTER(xsd:float(?value) >= #{options[:from]} AND xsd:float(?value) <= #{options[:to]}) . "
    elsif options[:querystring].is_numeric?
      query += "FILTER(xsd:float(?value) = #{options[:querystring]}) . "
    else
      query += "FILTER(REGEX(?value, '#{options[:querystring]}', 'i')) . "
    end
    if options[:attribute]
      query += "?data_point_uri dwc:measurementType <#{options[:attribute]}> . "
    end
    query += "}"
    unless options[:only_count]
      query += " LIMIT #{options[:per_page]} OFFSET #{((options[:page].to_i - 1) * options[:per_page])}"
    end
    puts query
    return query
  end

  # TODO - break down into friendlier syntax. :)
  def get_data
    return @rows if @rows
    rows = data
    rows.each do |row|
      if user_added_data = TaxonData.get_user_added_data(row[:data_point_uri])
        row[:user] = user_added_data.user
        row[:user_added_data] = user_added_data
        row[:source] = row[:user]
      end
      if row[:graph]
        row[:resource_id] = TaxonData.graph_name_to_resource_id(row[:graph])
      end
    end
    add_parents(rows)
    # bulk preloading of resources/content partners
    resources = Resource.find_all_by_id(rows.collect{ |r| r[:resource_id] }.compact.uniq, :include => :content_partner)
    rows.each do |row|
      if resource_id = row[:resource_id]
        if resource = resources.detect{ |r| r.id.to_s == resource_id }
          row[:source] = resource.content_partner
        end
      end
    end

    rows.delete_if{ |k,v| k[:attribute].blank? }
    rows = replace_licenses_with_mock_known_uris(rows)
    rows = TaxonData.add_known_uris_to_data(rows)
    rows = TaxonData.replace_taxon_concept_uris(rows, :target_taxon_concept_id)
    rows = TaxonData.sort_rows_by_attribute_and_value(rows)
    known_uris = rows.select { |d| d[:attribute].is_a?(KnownUri) }.map { |d| d[:attribute] }
    KnownUri.preload_associations(known_uris,
                                  [ { :toc_items => :translations },
                                    { :known_uri_relationships_as_subject => :to_known_uri },
                                    { :known_uri_relationships_as_target => :from_known_uri } ] )
    @categories = known_uris.flat_map(&:toc_items).uniq.compact
    @rows = rows
  end

  # This might actually want to move to another module, since it really belongs in TaxonOverview... of course, the
  # two would have to share the data-mining code, which is mostly what this module *does*, so... perhaps that's not a
  # keen idea. We'll leave it here until a clear parth forward presents itself:
  def get_data_for_overview
    if TaxonDataExemplar.exists?(taxon_concept_id: taxon_concept.id)
      return TaxonDataExemplar.rows_for_taxon_page(self)
    else
      rows = remove_data_for_demo(get_all_rows)
      rows = TaxonData.sort_rows_by_attribute_and_value(rows)[0..MAX_EXEMPLAR_DATA]
      add_parents(rows)
      rows.each do |row|
        TaxonDataExemplar.create(taxon_concept: taxon_concept, parent: row[:parent])
      end
      rows
    end
  end

  def get_all_rows
    # TODO - I added metadata back in because I needed to know whether things were user-added or partner-provided;
    # ideally we'll want to just pull enough additional info to make that distinction (should be simple enough)
    # rows = association_data(metadata: false) + measurement_data(metadata: false)
    # rows = get_data # (This is the line I replaced the code with)
    # rows.delete_if{ |k,v| k[:attribute].blank? }
    # rows = add_known_uris_to_data(rows)
    # rows = replace_target_taxon_concept_ids(rows)
    rows = get_data
    rows.delete_if { |k,v| k[:attribute].blank? }
    uniq_pairs(rows)
  end

  def categories
    get_data unless @categories
    @categories
  end

  private

  def self.sort_rows_by_attribute_and_value(rows)
    rows.sort_by do |row|
      attribute_label = EOL::Sparql.uri_components(row[:attribute])[:label]
      value_label = EOL::Sparql.uri_components(row[:value])[:label]
      value_label = value_label.to_s.downcase if value_label.class == RDF::Literal
      [ attribute_label.downcase, value_label.downcase ]
    end
  end

  # TODO: remove this after the demo - to be replaced by exemplar data
  def self.remove_data_for_demo(rows)
    uris_to_remove = [
      'http://iobis.org/maxaou',
      'http://iobis.org/minaou',
      'http://iobis.org/maxdate',
      'http://iobis.org/mindate'
    ]
    rows.delete_if do |r|
      if r[:attribute].is_a?(KnownUri)
        uris_to_remove.detect{ |uri| r[:attribute].matches(uri) }
      else
        uris_to_remove.detect{ |uri| r[:attribute].to_s == uri }
      end
    end
    rows
  end

  def self.get_user_added_data(value)
    if value && matches = value.to_s.match(UserAddedData::URI_REGEX)
      uad = UserAddedData.find(matches[1])
      return uad if uad
    end
    nil
  end

  def data
    TaxonData.group_data_by_graph_and_uri(measurement_data + association_data)
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
          ?data_point_uri a <#{DataMeasurement::CLASS_URI}>
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
    selects = "?attribute ?value ?target_taxon_concept_id ?inverse_attribute"
    if options[:metadata]
      selects += "?data_point_uri ?graph ?attribution_predicate ?attribution_object"
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
  def self.group_data_by_graph_and_uri(sparql_results)
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

  def self.group_metadata_for(prefix, result, result_metadata)
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

  def self.add_known_uris_to_data(rows)
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

  def self.add_known_uris_to_metadata(row, known_uris)
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

  def self.replace_with_uri(hash, key, known_uris)
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

  def self.replace_taxon_concept_uris(rows, taxon_concept_uri_key)
    rows.each do |r|
      if r.has_key?(taxon_concept_uri_key)
        r[taxon_concept_uri_key] = KnownUri.taxon_concept_id(r[taxon_concept_uri_key])
      end
    end
    rows
  end

  def self.uris_in_data(rows)
    uris  = rows.map { |row| row[:attribute] }.select { |attr| attr.is_a?(RDF::URI) }
    uris += rows.map { |row| row[:value] }.select { |attr| attr.is_a?(RDF::URI) }
    uris += rows.map { |row| row[:unit_of_measure_uri] }.select { |attr| attr.is_a?(RDF::URI) }
    uris += rows.map { |row| row[:metadata] ? row[:metadata].keys : nil }.flatten.compact.select { |attr| attr.is_a?(RDF::URI) }
    uris += rows.map { |row| row[:metadata] ? row[:metadata].values : nil }.flatten.compact.select { |attr| attr.is_a?(RDF::URI) }
    uris.map(&:to_s).uniq
  end

  def self.preload_target_taxon_concepts(rows)
    rows_with_taxon_data = rows.select{ |row| row.has_key?(:target_taxon_concept_id) }
    # bulk lookup all concepts for every row that has one
    taxon_concepts = TaxonConcept.find_all_by_id(rows_with_taxon_data.collect{ |row| row[:target_taxon_concept_id] }.
      compact.uniq, :include => { :preferred_common_names => :name })
    # now distribute the taxon concept instances to the appropriate rows
    rows_with_taxon_data.each do |row|
      if taxon_concept = taxon_concepts.detect{ |tc| tc.id.to_s == row[:target_taxon_concept_id] }
        row[:target_taxon_concept] = taxon_concept
      end
    end
    rows
  end

  def add_parents(rows)
    preload_data_point_uris(rows)
    rows.each { |row| row[:parent] = row[:user] ? row[:user_added_data] : row[:data_point_instance] }
  end

  def preload_data_point_uris(rows)
    partner_data = rows.select{ |d| d.has_key?(:data_point_uri) }
    data_point_uris = DataPointUri.find_all_by_taxon_concept_id_and_uri(taxon_concept.id, partner_data.collect{ |d| d[:data_point_uri].to_s }.compact.uniq)
    partner_data.each do |d|
      if data_point_uri = data_point_uris.detect{ |dp| dp.uri == d[:data_point_uri].to_s }
        d[:data_point_instance] = data_point_uri
      end
    end

    # NOTE - this is /slightly/ scary, as it generates new URIs on the fly
    partner_data.each do |d|
      d[:data_point_instance] ||= DataPointUri.find_or_create_by_taxon_concept_id_and_uri(taxon_concept.id, d[:data_point_uri].to_s)
    end
    DataPointUri.preload_associations(partner_data.collect{ |d| d[:data_point_instance] }, :all_comments)
  end

  # TODO - in my sample data (which had a single duplicate value for 'weight'), running this then caused the "more"
  # to go away.  :\  We may not care about such cases, though.
  def uniq_pairs(rows)
    h = {}
    rows.each { |r| h["#{r[:attribute]}:#{r[:value]}"] = r }
    h.values
  end

end
