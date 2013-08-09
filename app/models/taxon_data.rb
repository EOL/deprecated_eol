#encoding: utf-8
# NOTE - I had to change a whole bunch of "NOT IN" clauses because they weren't working (SPARQL syntax error in my
# version.)  I think this will be fixed in later versions (it works for PL), but for now, this seems to work.
class TaxonData < TaxonUserClassificationFilter

  DEFAULT_PAGE_SIZE = 30

  include Enumerable

  def self.search(options={})
    return nil if options[:querystring].blank?
    options[:per_page] ||= TaxonData::DEFAULT_PAGE_SIZE
    total_results = EOL::Sparql.connection.query(prepare_search_query(options.merge(:only_count => true))).first[:count].to_i
    results = EOL::Sparql.connection.query(prepare_search_query(options))
    KnownUri.add_to_data(results)
    WillPaginate::Collection.create(options[:page], options[:per_page], total_results) do |pager|
       pager.replace(results)
    end
  end

  def self.prepare_search_query(options={})
    options[:per_page] ||= TaxonData::DEFAULT_PAGE_SIZE
    options[:page] ||= 1
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
    return query
  end

  def downloadable?
    ! empty?
  end

  def empty?
    get_data.blank?
  end

  def each(&block)
    get_data.each { |row| yield(row) }
  end

  def topics
    @topics ||= get_data.map { |d| d[:attribute] }.select { |a| a.is_a?(KnownUri) }.uniq.compact.map(&:name)
  end

  def categories
    get_data unless @categories
    @categories
  end

  def get_data
    return @rows if @rows
    rows = TaxonDataSet.new(data, taxon_concept_id: taxon_concept.id, language: user.language)
    known_uris = rows.select { |d| d[:attribute].is_a?(KnownUri) }.map { |d| d[:attribute] }
    KnownUri.preload_associations(known_uris,
                                  [ { :toc_items => :translations },
                                    { :known_uri_relationships_as_subject => :to_known_uri },
                                    { :known_uri_relationships_as_target => :from_known_uri } ] )
    @categories = known_uris.flat_map(&:toc_items).uniq.compact
    @rows = rows
  end

  def get_data_for_overview
    picker = TaxonDataExemplarPicker.new(self)
    picker.pick(get_data)
  end

  private

  def data
    (measurement_data + association_data).delete_if { |k,v| k[:attribute].blank? }
  end

  def measurement_data(options = {})
    selects = "?attribute ?value ?unit_of_measure_uri ?data_point_uri ?graph"
    query = "
      SELECT DISTINCT #{selects}
      WHERE {
        GRAPH ?graph {
          ?data_point_uri a <#{DataMeasurement::CLASS_URI}> .
          ?data_point_uri dwc:measurementType ?attribute .
          ?data_point_uri dwc:measurementValue ?value .
          OPTIONAL {
            ?data_point_uri dwc:measurementUnit ?unit_of_measure_uri
          }
        } .
        {  ?data_point_uri dwc:taxonConceptID <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}> }
        UNION {
          ?data_point_uri dwc:occurrenceID ?occurrence .
          ?occurrence dwc:taxonID ?taxon .
          ?data_point_uri <http://eol.org/schema/measurementOfTaxon> 'true' .
          GRAPH ?resource_mappings_graph {
            ?taxon dwc:taxonConceptID <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}>
          }
        }
      }
      LIMIT 800"
    EOL::Sparql.connection.query(query)
  end

  def association_data(options = {})
    selects = "?attribute ?value ?target_taxon_concept_id ?inverse_attribute ?data_point_uri ?graph"
    query = "
      SELECT DISTINCT #{selects}
      WHERE {
        GRAPH ?resource_mappings_graph {
          ?taxon dwc:taxonConceptID <#{UserAddedData::SUBJECT_PREFIX}#{taxon_concept.id}> .
          ?value dwc:taxonConceptID ?target_taxon_concept_id
        } .
        GRAPH ?graph {
          ?occurrence dwc:taxonID ?taxon .
          ?target_occurrence dwc:taxonID ?value .
          ?data_point_uri a <#{DataAssociation::CLASS_URI}> .
          {
            ?data_point_uri dwc:occurrenceID ?occurrence .
            ?data_point_uri <http://eol.org/schema/targetOccurrenceID> ?target_occurrence .
            ?data_point_uri <http://eol.org/schema/associationType> ?attribute
          }
          UNION
          {
            ?data_point_uri dwc:occurrenceID ?target_occurrence .
            ?data_point_uri <http://eol.org/schema/targetOccurrenceID> ?occurrence .
            ?data_point_uri <http://eol.org/schema/associationType> ?inverse_attribute
          }
        } .
        OPTIONAL {
          GRAPH ?mappings {
            ?inverse_attribute owl:inverseOf ?attribute
          }
        }
      }
      LIMIT 800"
    EOL::Sparql.connection.query(query)
  end

  def self.preload_target_taxon_concepts(rows)
    rows_with_taxon_data = rows.select{ |row| row.has_key?(:target_taxon_concept_id) }
    # bulk lookup all concepts for every row that has one
    taxon_concepts = TaxonConcept.find_all_by_id(rows_with_taxon_data.collect{ |row| row[:target_taxon_concept_id] }.
      compact.uniq, :include => [ { :preferred_common_names => :name },
                                  { :preferred_entry => { :hierarchy_entry => { :name => :ranked_canonical_form } } } ] )
    # now distribute the taxon concept instances to the appropriate rows
    rows_with_taxon_data.each do |row|
      if taxon_concept = taxon_concepts.detect{ |tc| tc.id.to_s == row[:target_taxon_concept_id] }
        row[:target_taxon_concept] = taxon_concept
      end
    end
    rows
  end

end
