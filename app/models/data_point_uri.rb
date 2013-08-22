# Very stupid modle that just gives us a DataPointUri stored in the DB, for linking comments to. These are otherwise
# generated/stored in via SparQL.
class DataPointUri < ActiveRecord::Base

  include EOL::CuratableAssociation

  attr_accessible :string, :vetted_id, :visibility_id, :vetted, :visibility

  belongs_to :taxon_concept
  belongs_to :vetted
  belongs_to :visibility

  has_many :comments, :as => :parent
  has_many :all_versions, :class_name => DataPointUri.to_s, :foreign_key => :uri, :primary_key => :uri
  has_many :all_comments, :class_name => Comment.to_s, :through => :all_versions, :primary_key => :uri, :source => :comments
  has_many :taxon_data_exemplars

  # Required for commentable items. NOTE - This requires four queries from the DB, unless you preload the
  # information.  TODO - preload these:
  # TaxonConcept Load (10.3ms)  SELECT `taxon_concepts`.* FROM `taxon_concepts` WHERE `taxon_concepts`.`id` = 17
  # LIMIT 1
  # TaxonConceptPreferredEntry Load (15.0ms)  SELECT `taxon_concept_preferred_entries`.* FROM
  # `taxon_concept_preferred_entries` WHERE `taxon_concept_preferred_entries`.`taxon_concept_id` = 17 LIMIT 1
  # HierarchyEntry Load (0.8ms)  SELECT `hierarchy_entries`.* FROM `hierarchy_entries` WHERE
  # `hierarchy_entries`.`id` = 12 LIMIT 1
  # Name Load (0.5ms)  SELECT `names`.* FROM `names` WHERE `names`.`id` = 25 LIMIT 1
  def summary_name
    I18n.t(:data_point_uri_summary_name, :taxon => taxon_concept.summary_name)
  end

  def anchor
    "data_point_#{id}"
  end

  def get_metadata(language)
    query = "
      SELECT DISTINCT ?attribute ?value
      WHERE {
        GRAPH ?graph {
          {
            <#{uri}> ?attribute ?value .
          } UNION {
            <#{uri}> dwc:occurrenceID ?occurrence .
            ?occurrence ?attribute ?value .
          } UNION {
            ?measurement a <#{DataMeasurement::CLASS_URI}> .
            ?measurement <#{Rails.configuration.uri_parent_measurement_id}> <#{uri}> .
            ?measurement dwc:measurementType ?attribute .
            ?measurement dwc:measurementValue ?value .
          } UNION {
            <#{uri}> dwc:occurrenceID ?occurrence .
            ?measurement a <#{DataMeasurement::CLASS_URI}> .
            ?measurement dwc:occurrenceID ?occurrence .
            ?measurement dwc:measurementType ?attribute .
            ?measurement dwc:measurementValue ?value .
            OPTIONAL { ?measurement <#{Rails.configuration.uri_measurement_of_taxon}> ?measurementOfTaxon } .
            FILTER (?measurementOfTaxon != 'true')
          } UNION {
            ?measurement a <#{DataMeasurement::CLASS_URI}> .
            ?measurement <#{Rails.configuration.uri_association_id}> <#{uri}> .
            ?measurement dwc:measurementType ?attribute .
            ?measurement dwc:measurementValue ?value .
          } UNION {
            <#{uri}> dwc:occurrenceID ?occurrence .
            ?occurrence dwc:eventID ?event .
            ?event ?attribute ?value .
          }
          FILTER (?attribute NOT IN (rdf:type, dwc:taxonConceptID, dwc:measurementType, dwc:measurementValue,
                                     dwc:measurementID, <#{Rails.configuration.uri_reference_id}>,
                                     <#{Rails.configuration.uri_target_occurence}>, dwc:taxonID, dwc:eventID,
                                     <#{Rails.configuration.uri_association_type}>,
                                     dwc:measurementUnit, dwc:occurrenceID, <#{Rails.configuration.uri_measurement_of_taxon}>))
        }
      }"
    metadata_rows = EOL::Sparql.connection.query(query)
    metadata_rows = DataPointUri.replace_licenses_with_mock_known_uris(metadata_rows, language)
    KnownUri.add_to_data(metadata_rows)
    return nil if metadata_rows.empty?
    metadata_rows
  end

  def get_other_occurrence_measurements(language)
    query = "
      SELECT DISTINCT ?attribute ?value ?unit_of_measure_uri
      WHERE {
        GRAPH ?graph {
          {
            <#{uri}> dwc:occurrenceID ?occurrence .
            ?measurement a <#{DataMeasurement::CLASS_URI}> .
            ?measurement dwc:occurrenceID ?occurrence .
            ?measurement dwc:measurementType ?attribute .
            ?measurement dwc:measurementValue ?value .
            ?measurement <#{Rails.configuration.uri_measurement_of_taxon}> ?measurementOfTaxon .
            FILTER ( ?measurementOfTaxon = 'true' ) .
            OPTIONAL {
              ?measurement dwc:measurementUnit ?unit_of_measure_uri
            }
          }
        }
      }"
    occurrence_measurement_rows = EOL::Sparql.connection.query(query)
    # if there is only one response, then it is the original measurement
    return nil if occurrence_measurement_rows.length <= 1
    KnownUri.add_to_data(occurrence_measurement_rows)
    occurrence_measurement_rows
  end

  def get_references(language)
    options = []
    Rails.configuration.optional_reference_uris.each do |var, url|
      options << "OPTIONAL { ?reference <#{url}> ?#{var} } ."
    query = "
      SELECT DISTINCT ?identifier ?publicationType ?full_reference ?primaryTitle ?title ?pages ?pageStart ?pageEnd
         ?volume ?edition ?publisher ?authorList ?editorList ?created ?language ?uri ?doi ?localityName
      WHERE {
        GRAPH ?graph {
          {
            <#{uri}> <#{Rails.configuration.uri_reference_id}> ?reference .
            ?reference a <#{Rails.configuration.uri_reference}>
            #{options.join("\n")}
          }
        }
      }"
    reference_rows = EOL::Sparql.connection.query(query)
    return nil if reference_rows.empty?
    reference_rows
  end

  # Licenses are special (NOTE we also cache them here on a per-page basis...):
  def self.replace_licenses_with_mock_known_uris(metadata_rows, language)
    metadata_rows.each do |row|
      if row[:attribute] == UserAddedDataMetadata::LICENSE_URI && license = License.find_by_source_url(row[:value].to_s)
        row[:value] = KnownUri.new(:uri => row[:value],
          :translations => [ TranslatedKnownUri.new(:name => license.title, :language => language) ])
      end
    end
    metadata_rows
  end

end
