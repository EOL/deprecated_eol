# encoding: utf-8
# Gives us a SQL representation of a triple stored in the SparQL Database, so we can do rails-y things with it.
class DataPointUri < ActiveRecord::Base

  include EOL::CuratableAssociation

  # TODO - remove this once the #to_hash method is moved.
  include ActionView::Helpers::UrlHelper

  attr_accessible :string, :vetted_id, :visibility_id, :vetted, :visibility, :uri, :taxon_concept_id,
    :class_type, :predicate, :object, :unit_of_measure, :user_added_data_id, :resource_id,
    :predicate_known_uri_id, :object_known_uri_id, :unit_of_measure_known_uri_id,
    :predicate_known_uri, :object_known_uri, :unit_of_measure_known_uri

  belongs_to :taxon_concept
  belongs_to :vetted
  belongs_to :visibility
  belongs_to :resource
  belongs_to :user_added_data
  belongs_to :predicate_known_uri, :class_name => KnownUri.to_s, :foreign_key => :predicate_known_uri_id
  belongs_to :object_known_uri, :class_name => KnownUri.to_s, :foreign_key => :object_known_uri_id
  belongs_to :unit_of_measure_known_uri, :class_name => KnownUri.to_s, :foreign_key => :unit_of_measure_known_uri_id
  # this only applies to Associations, but is written as belongs_to to take advantage of preloading
  belongs_to :target_taxon_concept, :class_name => TaxonConcept.to_s, :foreign_key => :object

  has_many :comments, :as => :parent
  has_many :all_versions, :class_name => DataPointUri.to_s, :foreign_key => :uri, :primary_key => :uri
  has_many :all_comments, :class_name => Comment.to_s, :through => :all_versions, :primary_key => :uri, :source => :comments
  has_many :taxon_data_exemplars

  attr_accessor :metadata

  def self.preload_data_point_uris!(results, taxon_concept_id = nil)
    # There are potentially hundreds or thousands of DataPointUri inserts happening here.
    # The transaction makes the inserts much faster - no committing after each insert
    transaction do
      partner_data = results.select{ |d| d.has_key?(:data_point_uri) }
      data_point_uris = DataPointUri.find_all_by_uri(partner_data.collect{ |d| d[:data_point_uri].to_s }.compact.uniq)
      # NOTE - this is /slightly/ scary, as it generates new URIs on the fly
      partner_data.each do |row|
        if data_point_uri = data_point_uris.detect{ |dp| dp.uri == row[:data_point_uri].to_s }
          row[:data_point_instance] = data_point_uri
        end
        # setting the taxon_concept_id since it is not in the Virtuoso response
        row[:taxon_concept_id] ||= taxon_concept_id
        row[:data_point_instance] ||= DataPointUri.create_from_virtuoso_response(row)
        row[:data_point_instance].update_with_virtuoso_response(row)
      end
    end
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

  def self.create_from_virtuoso_response(row)
    new_attributes = DataPointUri.attributes_from_virtuoso_response(row)
    if data_point_uri = DataPointUri.find_by_uri(new_attributes[:uri])
      data_point_uri.update_with_virtuoso_response(row)
    else
      data_point_uri = DataPointUri.create(new_attributes)
    end
    data_point_uri
  end

  def self.attributes_from_virtuoso_response(row)
    attributes = { uri: row[:data_point_uri].to_s }
    # taxon_concept_id may come from solr as a URI, or set elsewhere as an Integer
    if row[:taxon_concept_id]
      if taxon_concept_id = KnownUri.taxon_concept_id(row[:taxon_concept_id])
        attributes[:taxon_concept_id] = taxon_concept_id
      elsif row[:taxon_concept_id].is_a?(Integer)
        attributes[:taxon_concept_id] = row[:taxon_concept_id]
      end
    end
    virtuoso_to_data_point_mapping = {
      :attribute => :predicate,
      :unit_of_measure_uri => :unit_of_measure,
      :value => :object }
    virtuoso_to_data_point_mapping.each do |virtuoso_response_key, data_point_uri_key|
      next if row[virtuoso_response_key].blank?
      # this requires that
      if row[virtuoso_response_key].is_a?(KnownUri)
        attributes[data_point_uri_key] = row[virtuoso_response_key].uri
        # each of these attributes has a corresponging known_uri_id (e.g. predicate_known_uri_id)
        attributes[(data_point_uri_key.to_s + "_known_uri_id").to_sym] = row[virtuoso_response_key].id
        # setting the instance as well to take advantage of preloaded associations on KnownUri
        attributes[(data_point_uri_key.to_s + "_known_uri").to_sym] = row[virtuoso_response_key]
      else
        attributes[data_point_uri_key] = row[virtuoso_response_key].to_s
      end
    end

    if row[:target_taxon_concept_id]
      attributes[:class_type] = 'Association'
      attributes[:object] = row[:target_taxon_concept_id].to_s.split("/").last
    else
      attributes[:class_type] = 'MeasurementOrFact'
    end
    if row[:graph] == Rails.configuration.user_added_data_graph
      attributes[:user_added_data_id] = row[:data_point_uri].to_s.split("/").last
    else
      attributes[:resource_id] = row[:graph].to_s.split("/").last
    end
    attributes
  end

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

  def header_anchor
    "predicate_#{predicate.gsub(/[^_A-Za-z0-9]/, '_')}"
  end

  def anchor
    "data_point_#{id}"
  end

  def source
    return user_added_data.user if user_added_data
    return resource.content_partner if resource
  end

  def predicate_uri
    predicate_known_uri || predicate
  end

  def object_uri
    object_known_uri || object
  end

  def unit_of_measure_uri
    _unit_of_measure_uri(unit_of_measure_known_uri, unit_of_measure)
  end

  def original_unit_of_measure_uri
    _unit_of_measure_uri(original_unit_of_measure_known_uri, original_unit_of_measure)
  end

  def _unit_of_measure_uri(known, other)
    return known if known
    return other if other
    if implied_unit = implied_unit_of_measure_known_uri
      implied_unit.uri
    end
  end

  def implied_unit_of_measure_known_uri
    predicate_known_uri.implied_unit_of_measure if predicate_known_uri
  end

  def measurement?
    class_type == 'MeasurementOrFact'
  end

  def association?
    class_type == 'Association'
  end

  def get_metadata(language)
    DataPointUri.assign_metadata(self, language)
    metadata
  end

  def self.assign_bulk_metadata(data_point_uris, language)
    data_point_uris.each_slice(1000){ |d| assign_metadata(d, language) }
  end

  def self.assign_metadata(data_point_uris, language)
    data_point_uris = [ data_point_uris ] unless data_point_uris.is_a?(Array)
    uris_to_lookup = data_point_uris.select{ |d| d.metadata.nil? }.collect(&:uri)
    return if uris_to_lookup.empty?
    query = "
      SELECT DISTINCT ?parent_uri ?attribute ?value ?unit_of_measure_uri
      WHERE {
        GRAPH ?graph {
          {
            ?parent_uri ?attribute ?value .
          } UNION {
            ?parent_uri dwc:occurrenceID ?occurrence .
            ?occurrence ?attribute ?value .
          } UNION {
            ?measurement <#{Rails.configuration.uri_parent_measurement_id}> ?parent_uri .
            ?measurement dwc:measurementType ?attribute .
            ?measurement dwc:measurementValue ?value .
            OPTIONAL { ?measurement dwc:measurementUnit ?unit_of_measure_uri } .
          } UNION {
            ?parent_uri dwc:occurrenceID ?occurrence .
            ?measurement dwc:occurrenceID ?occurrence .
            ?measurement dwc:measurementType ?attribute .
            ?measurement dwc:measurementValue ?value .
            OPTIONAL { ?measurement <#{Rails.configuration.uri_measurement_of_taxon}> ?measurementOfTaxon } .
            OPTIONAL { ?measurement dwc:measurementUnit ?unit_of_measure_uri } .
            FILTER (?measurementOfTaxon != 'true')
          } UNION {
            ?measurement <#{Rails.configuration.uri_association_id}> ?parent_uri .
            ?measurement dwc:measurementType ?attribute .
            ?measurement dwc:measurementValue ?value .
            OPTIONAL { ?measurement dwc:measurementUnit ?unit_of_measure_uri } .
          } UNION {
            ?parent_uri dwc:occurrenceID ?occurrence .
            ?occurrence dwc:eventID ?event .
            ?event ?attribute ?value .
          }
          FILTER (?attribute NOT IN (rdf:type, dwc:taxonConceptID, dwc:measurementType, dwc:measurementValue,
                                     dwc:measurementID, <#{Rails.configuration.uri_reference_id}>,
                                     <#{Rails.configuration.uri_target_occurence}>, dwc:taxonID, dwc:eventID,
                                     <#{Rails.configuration.uri_association_type}>,
                                     dwc:measurementUnit, dwc:occurrenceID, <#{Rails.configuration.uri_measurement_of_taxon}>)
                  ) .
          FILTER (?parent_uri IN (<#{uris_to_lookup.join('>,<')}>))
        }
      }"
    metadata_rows = EOL::Sparql.connection.query(query)
    metadata_rows = DataPointUri.replace_licenses_with_mock_known_uris(metadata_rows, language)
    KnownUri.add_to_data(metadata_rows)
    # not using TaxonDataSet here since that would create DataPointURI entries in the database, and we really
    # don't have any need for tons of metadata in MySQL, just primary measurements and associations
    metadata_rows.each do |row|
      data_point_uri = DataPointUri.new(DataPointUri.attributes_from_virtuoso_response(row))
      data_point_uri.convert_units
      row[:data_point_uri] = data_point_uri
    end
    data_point_uris.each do |d|
      d.metadata = metadata_rows.select{ |row| row[:parent_uri] == d.uri }.collect{ |row| row[:data_point_uri] }
    end
  end

  def get_other_occurrence_measurements(language)
    query = "
      SELECT DISTINCT ?attribute ?value ?unit_of_measure_uri ?data_point_uri ?graph ?taxon_concept_id
      WHERE {
        GRAPH ?graph {
          {
            <#{uri}> dwc:occurrenceID ?occurrence .
            ?data_point_uri dwc:occurrenceID ?occurrence .
            ?data_point_uri dwc:measurementType ?attribute .
            ?data_point_uri dwc:measurementValue ?value .
            ?data_point_uri <#{Rails.configuration.uri_measurement_of_taxon}> ?measurementOfTaxon .
            ?occurrence dwc:taxonID ?taxon_id .
            FILTER ( ?measurementOfTaxon = 'true' ) .
            OPTIONAL {
              ?data_point_uri dwc:measurementUnit ?unit_of_measure_uri
            }
          }
        }
        ?taxon_id dwc:taxonConceptID ?taxon_concept_id
      }"
    occurrence_measurement_rows = EOL::Sparql.connection.query(query)
    # if there is only one response, then it is the original measurement
    return nil if occurrence_measurement_rows.length <= 1
    TaxonDataSet.new(occurrence_measurement_rows, preload: false)
  end

  # NOTE - User-added data references aren't added with these URIs and therefore don't get "seen" by this method.
  # TODO - (low priority) fix that; we should get user-added references.
  def get_references(language)
    options = []
    # TODO - no need to keep rebuilding this, put it in a class variable.
    Rails.configuration.optional_reference_uris.each do |var, url|
      options << "OPTIONAL { ?reference <#{url}> ?#{var} } ."
    end
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
    EOL::Sparql.connection.query(query)
  end

  def show(user)
    set_visibility(user, Visibility.visible.id)
    user_added_data.show(user) if user_added_data
  end

  def hide(user)
    set_visibility(user, Visibility.invisible.id)
    user_added_data.hide(user) if user_added_data
  end

  def update_with_virtuoso_response(row)
    new_attributes = DataPointUri.attributes_from_virtuoso_response(row)
    new_attributes.each do |k, v|
      send("#{k}=", v)
    end
    save if changed?
  end

  def convert_units
    if (self.object.is_a?(Float) || self.object.to_s.is_numeric?)
      original_value = self.object
      while apply_unit_conversion
        # wait while there are no more conversions performed
      end
    end
  end

  def apply_unit_conversion
    # we can use either the unit in the medata, or the one implied by the predicate
    if self.unit_of_measure_known_uri
      unit_known_uri = self.unit_of_measure_known_uri
    elsif implied_unit_of_measure_known_uri
      unit_known_uri = implied_unit_of_measure_known_uri
    else
      # if we have no unit then there is no conversion to be done
      return false
    end
    DataPointUri.conversions.select{ |c| c[:starting_units].include?(unit_known_uri.uri) }.each do |c|
      potential_new_value = c[:function].call(self.object.to_f)
      next if c[:required_minimum] && potential_new_value < c[:required_minimum]
      self.original_unit_of_measure = unit_of_measure
      self.original_unit_of_measure_known_uri = unit_of_measure_known_uri
      self.object = potential_new_value
      self.unit_of_measure = c[:ending_unit].uri
      self.unit_of_measure_known_uri = c[:ending_unit]
      return true
    end
    false
  end

  def original_unit_of_measure=(val)
    @original_unit_of_measure = val
  end

  def original_unit_of_measure
    @original_unit_of_measure || unit_of_measure
  end

  def original_unit_of_measure_known_uri=(val)
    @original_unit_of_measure_known_uri = val
  end

  def original_unit_of_measure_known_uri
    @original_unit_of_measure_known_uri || unit_of_measure_known_uri
  end

  # Note... this method is actually kind of view-like (something like XML Builder would be ideal) and perhaps shouldn't be in
  # this model class.
  def to_hash(language = Language.default, options = {})
    tc = options[:taxa] && options[:taxa].map(&:id).include?(taxon_concept_id) ?
      options[:taxa].detect { |tc| tc.id == taxon_concept_id } : # Yay! They cached it for us.
      taxon_concept # Load it. This will be painful.
    hash = if tc
             {
      # Taxon Concept ID:
      I18n.t(:data_column_tc_id) => taxon_concept_id,
      # WAIT - # Some classification context (stealing from search for now):
      # WAIT - I18n.t(:data_column_classification_summary) => taxon_concept.entry.preferred_classification_summary,
      # Scientific Name:
      I18n.t(:data_column_sci_name) => tc.nil? ? '' : tc.title_canonical,
      # Common Name:
      I18n.t(:data_column_common_name) => tc.nil? ? '' : tc.preferred_common_name_in_language(language)
             }
           else
             {}
           end
    # Nice measurement:
    hash[I18n.t(:data_column_measurement)] = predicate_uri.try(:label) || ''
    hash[I18n.t(:data_column_value)] = value_string(language)
    # URI measurement / value
    hash[I18n.t(:data_column_measurement_uri)] = predicate
    hash[I18n.t(:data_column_value_uri)] = value_uri_or_blank
    # Units:
    hash[I18n.t(:data_column_units)] = units_safe(:label)
    # Units URI:
    hash[I18n.t(:data_column_units_uri)] = units_uri
    # Raw value:
    hash[I18n.t(:data_column_raw_value)] = DataValue.new(object_uri).label
    # Raw Units:
    hash[I18n.t(:data_column_raw_units)] = original_units_safe(:label)
    # Raw Units URI:
    hash[I18n.t(:data_column_raw_units_uri)] = original_units_uri
    # Source:
    hash[I18n.t(:data_column_source)] = source.try(:name) || ''
    # Resource:
    if resource
      hash[I18n.t(:data_column_resource)] =
        # Ewww. TODO - as I say at the start of the method, this really belongs in a view:
        Rails.application.routes.url_helpers.content_partner_resource_url(resource.content_partner, resource,
                                                                          host: options[:host])
    end
    metadata = get_metadata(language)
    unless metadata.empty?
      metadata.each do |datum|
        key = EOL::Sparql.uri_components(datum.predicate_uri)[:label]
        if hash.has_key?(key) # Uh-oh. Make it original, please:
          orig_key = key.dup
          count = 1
          key = "#{orig_key} #{count += 1}" while hash.has_key?(key)
        end
        hash[key] = datum.value_string(language)
      end
    end
    refs = get_references(language)
    unless refs.empty?
      hash[I18n.t(:reference)] = refs.map { |r| r[:full_reference].to_s }.join("\n")
    end
    # TODO - other measurements. ...I think.
    hash
  end

  def value_uri_or_blank
    EOL::Sparql.is_uri?(object) ? object : ''
  end

  # TODO - a lot of this stuff should be extracted to a class to handle ... this kind of stuff.  :| (DataValue, perhaps) It's
  # really very simple, but there's enough of it that it seems quite complex.
  def units_string
    units_safe(:label)
  end

  def units_uri
    units_safe(:uri)
  end

  def original_units_uri
    original_units_safe(:uri)
  end

  def units_safe(attr)
    _units_safe(units, attr)
  end

  def original_units_safe(attr)
    _units_safe(original_units, attr)
  end

  # TODO - this logic is duplicated in the taxa helper; remove it from there. Maybe move to DataValue?
  def value_string(lang = Language.default)
    if association? && target_taxon_concept
      common = target_taxon_concept.preferred_common_name_in_language(lang)
      return target_taxon_concept.title_canonical if common.blank?
      common
    else
      val = EOL::Sparql.uri_components(object_uri)[:label].to_s # TODO - see if we need that #to_s; seems redundant.
      if val.is_numeric?
        # float values can be rounded off to 2 decimal places
        val = val.to_f.round(2) if val.is_float?
      else
        # other values may have links embedded in them (references, citations, etc.)
        val.add_missing_hyperlinks
      end
      val
    end
  end

  # NOTE - Sadly, when using scopes here, it loads each scope for each instance, separately. (WTF?) So I'm not using scopes, I'm
  # using selects.
  def included?
    taxon_data_exemplars.select(&:included?).any?
  end

  def excluded?
    taxon_data_exemplars.select(&:excluded?).any?
  end

  def <=>(other)
    if included? && ! other.included?
      -1
    elsif other.included? && ! included?
      1
    elsif excluded? && ! other.excluded?
      1
    elsif other.excluded? && ! excluded?
      -1
    else
      # TODO - really, this should sort on the predicate first, value second. ...We never need that, but it still violates
      # principle of least surprise:
      value_uri_or_blank <=> other.value_uri_or_blank
    end
  end

private

  def units
    _units(unit_of_measure_uri)
  end

  def original_units
    _units(original_unit_of_measure_uri)
  end

  # TODO - this logic is duplicated in the taxa helper; remove it from there. ...Actually, this belongs on DataValue, I think.
  def _units(which)
    if which && uri_components = EOL::Sparql.explicit_measurement_uri_components(which)
      uri_components
    elsif uri_components = EOL::Sparql.implicit_measurement_uri_components(predicate_uri)
      uri_components
    end
  end

  def _units_safe(which, attr)
    which && which.has_key?(attr) ? which[attr] : ''
  end

  def self.conversions
    # lots of raw URIs in here to convert some common and duplicate URIs
    # We wouldn't want to, for example, use use create_defaults to have named methods
    # in KnownURI for all these URIs
    # TODO: replace this with a new table and an admin interface for setting unit conversions
    return @@conversions if defined?(@@conversions)
    @@conversions = [
      { starting_units:   [ KnownUri.milligrams.uri ],
        ending_unit:      KnownUri.grams.uri,
        function:         lambda { |v| v / 1000 },
        required_minimum: 1.0 },
      { starting_units:   [ KnownUri.grams.uri, 'http://adw.org/g', 'http://anage.org/g' ],
        ending_unit:      KnownUri.kilograms.uri,
        function:         lambda { |v| v / 1000 },
        required_minimum: 1.0 },
      { starting_units:   [ KnownUri.millimeters.uri, 'http://adw.org/mm' ],
        ending_unit:      KnownUri.centimeters.uri,
        function:         lambda { |v| v / 10 },
        required_minimum: 1.0 },
      { starting_units:   [ KnownUri.centimeters.uri ],
        ending_unit:      KnownUri.meters.uri,
        function:         lambda { |v| v / 100 },
        required_minimum: 1.0 } ,
      { starting_units:   [ KnownUri.kelvin.uri, 'http://anage.org/k' ],
        ending_unit:      KnownUri.celsius.uri,
        function:         lambda { |v| v - 273.15 } },
      { starting_units:   [ KnownUri.days.uri, 'http://anage.org/days', 'http://eol.org/schema/terms/day' ],
        ending_unit:      KnownUri.years.uri,
        function:         lambda { |v| v / 365 },
        required_minimum: 1.0 },
      { starting_units:   [ Rails.configuration.schema_terms_prefix + 'onetenthdegreescelsius' ],
        ending_unit:      KnownUri.grams.uri,
        function:         lambda { |v| v / 10 } },
      { starting_units:   [ Rails.configuration.schema_terms_prefix + 'log10gram' ],
        ending_unit:      KnownUri.grams.uri,
        function:         lambda { |v| 10 ** v } },
      { starting_units:   [ Rails.configuration.schema_terms_prefix + 'squareMicrometer' ],
        ending_unit:      Rails.configuration.uri_obo + 'UO_0000082',                   # square millimeter
        function:         lambda { |v| v / 1000000 },
        required_minimum: 1.0 },
      { starting_units:   [ Rails.configuration.uri_obo + 'UO_0000082' ],               # square millimeter
        ending_unit:      Rails.configuration.uri_obo + 'UO_0000081',                   # square centimeter
        function:         lambda { |v| v / 100 },
        required_minimum: 1.0 },
      { starting_units:   [ Rails.configuration.uri_obo + 'UO_0000081' ],               # square centimeter
        ending_unit:      Rails.configuration.uri_obo + 'UO_0000080',                   # square meter
        function:         lambda { |v| v / 10000 },
        required_minimum: 1.0 },
      { starting_units:   [ Rails.configuration.uri_obo + 'UO_0000080' ],               # square meter
        ending_unit:      Rails.configuration.schema_terms_prefix + 'squarekilometer',  # square kilometer
        function:         lambda { |v| v / 1000000 },
        required_minimum: 1.0 }
    ]
    KnownUri.find_all_by_uri(@@conversions.collect{ |c| c[:ending_unit] }).each do |known_uri|
      @@conversions.select{ |conversion| conversion[:ending_unit] == known_uri.uri }.each do |conversion|
        conversion[:ending_unit] = known_uri
      end
    end
    @@conversions.delete_if{ |conversion| ! conversion[:ending_unit].is_a?(KnownUri) ||
                                          ! conversion[:ending_unit].unit_of_measure? }
    @@conversions
  end

end
