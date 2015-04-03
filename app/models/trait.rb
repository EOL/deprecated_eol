# encoding: utf-8
#
# Gives us a SQL representation of a triple stored in the SparQL Database, so we
# can do rails-y things with it.
#
# TODO - it is really unclear how predicate and object work... how do I set them
# in tests, how do I know if they are URIs, why are there sixteen flavors of
# each?  ...This needs to be re-engineered.
class Trait < ActiveRecord::Base

  include EOL::CuratableAssociation
  # TODO - remove this once the #to_hash method is moved.
  include ActionView::Helpers::UrlHelper

  attr_accessible :string, :vetted_id, :visibility_id, :vetted, :visibility,
  :uri, :taxon_concept_id, :class_type, :predicate, :object, :unit_of_measure,
  :user_added_data_id, :resource_id, :predicate_known_uri_id,
  :object_known_uri_id, :unit_of_measure_known_uri_id, :predicate_known_uri,
  :object_known_uri, :unit_of_measure_known_uri, :statistical_method,
  :statistical_method_known_uri, :statistical_method_known_uri_id, :life_stage,
  :life_stage_known_uri, :life_stage_known_uri_id, :sex, :sex_known_uri,
  :sex_known_uri_id

  attr_accessor :metadata, :references, :statistical_method,
  :statistical_method_known_uri, :statistical_method_known_uri_id, :life_stage,
  :life_stage_known_uri, :life_stage_known_uri_id, :sex, :sex_known_uri,
  :sex_known_uri_id, :original_unit_of_measure,
  :original_unit_of_measure_known_uri, :original_value

  belongs_to :taxon_concept
  belongs_to :vetted
  belongs_to :visibility
  belongs_to :resource
  belongs_to :user_added_data
  belongs_to :predicate_known_uri, class_name: KnownUri.to_s,
    foreign_key: :predicate_known_uri_id
  belongs_to :object_known_uri, class_name: KnownUri.to_s,
    foreign_key: :object_known_uri_id
  belongs_to :unit_of_measure_known_uri, class_name: KnownUri.to_s,
    foreign_key: :unit_of_measure_known_uri_id
  # this only applies to Associations, but is written as belongs_to to take
  # advantage of preloading
  belongs_to :target_taxon_concept, class_name: TaxonConcept.to_s, foreign_key: :object

  has_many :comments, as: :parent
  has_many :all_versions, class_name: Trait.to_s, foreign_key: :uri, primary_key: :uri
  has_many :all_comments, class_name: Comment.to_s, through: :all_versions,
    primary_key: :uri, source: :comments
  has_many :taxon_data_exemplars

  before_save :default_visibility

  def self.preload_traits!(results, taxon_concept_id = nil)
    # There are potentially hundreds or thousands of Trait inserts
    # happening here. The transaction makes the inserts much faster - no
    # committing after each insert
    transaction do
      partner_data = results.select { |d| d.has_key?(:trait) }
      traits = Trait.where(
        uri: partner_data.map { |d| d[:trait].to_s }.compact.uniq
      )
      # Use the index, if we can (we cannot on searches):
      traits = traits.
        where(taxon_concept_id: taxon_concept_id) if
        taxon_concept_id
      # NOTE - this is /slightly/ scary, as it generates new URIs on the fly
      partner_data.each do |row|
        if trait = traits.
          detect { |dp| dp.uri == row[:trait].to_s }
          row[:data_point_instance] = trait
        end
        # setting the taxon_concept_id since it is not in the Virtuoso response
        row[:taxon_concept_id] ||= taxon_concept_id
        row[:data_point_instance] ||= Trait.create_from_virtuoso_response(row)
        row[:data_point_instance].update_with_virtuoso_response(row)
      end
    end
  end

  def self.initialize_labels_in_language(traits, language = Language.default)
    traits.each do |trait|
      # calling value_string now while we have the proper language for loading
      # the proper translations and common names. This will cache the value for
      # use later, such as in sorting
      trait.value_string(language)
    end
  end

  # Licenses are special (NOTE we also cache them here on a per-page basis...):
  # TODO: This is supremely stupid. Handle it in the view.... or just let the
  # KnownUris be aware of licenses; is that so bad?
  def self.replace_licenses_with_mock_known_uris(metadata_rows, language)
    metadata_rows.each do |row|
      if row[:attribute] == UserAddedDataMetadata::LICENSE_URI &&
        license = License.find_by_source_url(row[:value].to_s)
        row[:value] = KnownUri.new(
          uri: row[:value],
          translations: [
            TranslatedKnownUri.new(name: license.title, language: language)
          ]
        )
      end
    end
    metadata_rows
  end

  def self.create_from_virtuoso_response(row)
    new_attributes = Trait.attributes_from_virtuoso_response(row)
    if trait = Trait.find_by_taxon_concept_id_and_uri(
      new_attributes[:taxon_concept_id], new_attributes[:uri]
    )
      trait.update_with_virtuoso_response(row)
    else
      trait = Trait.create(new_attributes)
    end
    trait
  end

  def self.attributes_from_virtuoso_response(row)
    attributes = { uri: row[:trait].to_s }
    # taxon_concept_id may come from solr as a URI, or set elsewhere as an Integer
    if row[:taxon_concept_id]
      if taxon_concept_id = KnownUri.taxon_concept_id(row[:taxon_concept_id])
        attributes[:taxon_concept_id] = taxon_concept_id
      elsif row[:taxon_concept_id].is_a?(Integer)
        attributes[:taxon_concept_id] = row[:taxon_concept_id]
      end
    end
    virtuoso_to_data_point_mapping = {
      attribute: :predicate,
      unit_of_measure_uri: :unit_of_measure,
      value: :object,
      statistical_method: :statistical_method,
      life_stage: :life_stage,
      sex: :sex }
    virtuoso_to_data_point_mapping.each do |virtuoso_response_key, trait_key|
      next if row[virtuoso_response_key].blank?
      # this requires that
      if row[virtuoso_response_key].is_a?(KnownUri)
        attributes[trait_key] = row[virtuoso_response_key].uri
        # each of these attributes has a corresponging known_uri_id (e.g.
        # predicate_known_uri_id)
        attributes[(trait_key.to_s + "_known_uri_id").to_sym] =
          row[virtuoso_response_key].id
        # setting the instance as well to take advantage of preloaded
        # associations on KnownUri
        attributes[(trait_key.to_s + "_known_uri").to_sym] = row[virtuoso_response_key]
      else
        attributes[trait_key] = row[virtuoso_response_key].to_s
      end
    end

    if row[:target_taxon_concept_id]
      attributes[:class_type] = 'Association'
      attributes[:object] = row[:target_taxon_concept_id].to_s.split("/").last
    else
      attributes[:class_type] = 'MeasurementOrFact'
    end
    if row[:graph] == Rails.configuration.user_added_data_graph
      attributes[:user_added_data_id] = row[:trait].to_s.split("/").last
    else
      attributes[:resource_id] = row[:graph].to_s.split("/").last
    end
    attributes
  end

  # Required for commentable items. NOTE - This requires four queries from the
  # DB, unless you preload the information.  TODO - preload these: TaxonConcept
  # Load (10.3ms)  SELECT `taxon_concepts`.* FROM `taxon_concepts` WHERE
  # `taxon_concepts`.`id` = 17 LIMIT 1 TaxonConceptPreferredEntry Load (15.0ms)
  # SELECT `taxon_concept_preferred_entries`.* FROM
  # `taxon_concept_preferred_entries` WHERE
  # `taxon_concept_preferred_entries`.`taxon_concept_id` = 17 LIMIT 1
  # HierarchyEntry Load (0.8ms)  SELECT `hierarchy_entries`.* FROM
  # `hierarchy_entries` WHERE `hierarchy_entries`.`id` = 12 LIMIT 1 Name Load
  # (0.5ms)  SELECT `names`.* FROM `names` WHERE `names`.`id` = 25 LIMIT 1
  def summary_name
    I18n.t(:trait_summary_name, taxon: taxon_concept.summary_name)
  end

  def header_anchor
    "predicate_#{predicate.gsub(/[^_A-Za-z0-9]/, '_')}"
  end

  def anchor
    "data_point_#{id}"
  end

  def to_jsonld(options = {})
    jsonld = {
      '@id' => uri,
      'trait_id' => id,
      '@type' => measurement? ? 'dwc:MeasurementOrFact' : 'eol:Association',
      'dwc:taxonID' => KnownUri.taxon_uri(taxon_concept_id) }
    if value = Trait.jsonld_value_from_string_or_known_uri(predicate_known_uri ||
      predicate)
      type_key = measurement? ? 'dwc:measurementType' : 'eol:associationType'
      jsonld[type_key] = value
    end
    if association?
      jsonld['eol:targetTaxonID'] = KnownUri.taxon_uri(object)
    elsif value = Trait.jsonld_value_from_string_or_known_uri(object_known_uri ||
      object)
      jsonld['dwc:measurementValue'] = value
    end
    if value = Trait.jsonld_value_from_string_or_known_uri(unit_of_measure_known_uri ||
      unit_of_measure)
      jsonld['dwc:measurementUnit'] = value
    end
    if value = Trait.jsonld_value_from_string_or_known_uri(life_stage_known_uri ||
      life_stage)
      jsonld['dwc:lifeStage'] = value
    end
    if value = Trait.jsonld_value_from_string_or_known_uri(sex_known_uri || sex)
      jsonld['dwc:sex'] = value
    end
    if value =
      Trait.jsonld_value_from_string_or_known_uri(statistical_method_known_uri ||
      statistical_method)
      jsonld['eolterms:statisticalMethod'] = value
    end
    add_metadata_to_hash(jsonld) if options[:metadata]
    jsonld
  end

  def self.jsonld_value_from_string_or_known_uri(string_or_known_uri)
    if string_or_known_uri
      if string_or_known_uri.is_a?(KnownUri)
        { 'rdfs:label' => { 'en' => string_or_known_uri.label('en') },
          '@id' => string_or_known_uri.uri }
      else
        if EOL::Sparql.is_uri?(string_or_known_uri)
          { '@id' => string_or_known_uri }
        elsif implied_unit =
          EOL::Sparql.implied_unit_of_measure_for_uri(string_or_known_uri)
          { 'rdfs:label' => { 'en' => implied_unit.label('en') },
            '@id' => implied_unit.uri }
        else
          "#{string_or_known_uri}"
        end
      end
    end
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
    Trait.with_master do
      Trait.assign_metadata(self, language)
      metadata
    end
  end

  def self.assign_bulk_metadata(traits, language)
    traits.each_slice(1000){ |d| assign_metadata(d, language) }
  end

  def self.assign_metadata(traits, language)
    traits = [ traits ] unless traits.is_a?(Array)
    uris_to_lookup = traits.select{ |d| d.metadata.nil? }.collect(&:uri)
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
            ?measurement eol:parentMeasurementID ?parent_uri .
            ?measurement dwc:measurementType ?attribute .
            ?measurement dwc:measurementValue ?value .
            OPTIONAL { ?measurement dwc:measurementUnit ?unit_of_measure_uri } .
          } UNION {
            ?parent_uri dwc:occurrenceID ?occurrence .
            ?measurement dwc:occurrenceID ?occurrence .
            ?measurement dwc:measurementType ?attribute .
            ?measurement dwc:measurementValue ?value .
            FILTER NOT EXISTS { ?measurement eol:measurementOfTaxon eolterms:true } .
            OPTIONAL { ?measurement dwc:measurementUnit ?unit_of_measure_uri } .
          } UNION {
            ?measurement eol:associationID ?parent_uri .
            ?measurement dwc:measurementType ?attribute .
            ?measurement dwc:measurementValue ?value .
            OPTIONAL { ?measurement dwc:measurementUnit ?unit_of_measure_uri } .
          } UNION {
            ?parent_uri dwc:occurrenceID ?occurrence .
            ?occurrence dwc:eventID ?event .
            ?event ?attribute ?value .
          } UNION {
            ?parent_uri dwc:occurrenceID ?occurrence .
            ?occurrence dwc:taxonID ?taxon .
            ?taxon ?attribute ?value .
            FILTER (?attribute = dwc:scientificName)
          }
          FILTER (
            ?attribute NOT IN (
              rdf:type, dwc:taxonConceptID, dwc:measurementType,
              dwc:measurementValue, dwc:measurementID, eolreference:referenceID,
              eol:targetOccurrenceID, dwc:taxonID, dwc:eventID, eol:associationType,
              dwc:measurementUnit, dwc:occurrenceID, eol:measurementOfTaxon)
            ) .
            FILTER (?parent_uri IN (<#{uris_to_lookup.join('>,<')}>)
          )
        }
      }"
    metadata_rows = EOL::Sparql.connection.query(query)
    metadata_rows =
      Trait.replace_licenses_with_mock_known_uris(metadata_rows, language)
    KnownUri.add_to_data(metadata_rows)
    # not using TaxonDataSet here since that would create Trait entries in the
    # database, and we really don't have any need for tons of metadata in MySQL,
    # just primary measurements and associations
    metadata_rows.each do |row|
      trait = Trait.new(Trait.attributes_from_virtuoso_response(row))
      trait.convert_units
      row[:trait] = trait
    end
    traits.each do |d|
      d.metadata = metadata_rows.select { |row| row[:parent_uri] == d.uri }.
        collect{ |row| row[:trait] }
    end
  end

  def get_other_occurrence_measurements(language)
    Trait.with_master do
      query = "
        SELECT DISTINCT ?attribute ?value ?unit_of_measure_uri ?trait ?graph
          ?taxon_concept_id ?measurementOfTaxon
        WHERE {
          GRAPH ?graph {
            {
              <#{uri}> dwc:occurrenceID ?occurrence .
              ?trait dwc:occurrenceID ?occurrence .
              ?trait dwc:measurementType ?attribute .
              ?trait dwc:measurementValue ?value .
              ?trait eol:measurementOfTaxon ?measurementOfTaxon .
              ?occurrence dwc:taxonID ?taxon_id .
              OPTIONAL {
                ?trait dwc:measurementUnit ?unit_of_measure_uri
              }
            }
          }
          ?taxon_id dwc:taxonConceptID ?taxon_concept_id
        }"
      occurrence_measurement_rows =
        EOL::Sparql.connection.query(query).
          delete_if { |r| r[:measurementOfTaxon] != Rails.configuration.uri_true }
      # if there is only one response, then it is the original measurement
      return nil if occurrence_measurement_rows.length <= 1
      traits = TaxonDataSet.new(occurrence_measurement_rows, preload: false)
    end
  end

  def get_references(language)
    Trait.with_master do
      Trait.assign_references(self, language)
      references
    end
  end

  def self.assign_bulk_references(traits, language)
    traits.each_slice(1000){ |d| assign_references(d, language) }
  end

  # NOTE - User-added data references aren't added with these URIs and therefore
  # don't get "seen" by this method. TODO - (low priority) fix that; we should
  # get user-added references.
  def self.assign_references(traits, language)
    traits = [ traits ] unless traits.is_a?(Array)
    uris_to_lookup = traits.select{ |d| d.references.nil? }.collect(&:uri)
    return if uris_to_lookup.empty?
    options = []
    # TODO - no need to keep rebuilding this, put it in a class variable.
    Rails.configuration.optional_reference_uris.each do |var, url|
      options << "OPTIONAL { ?reference <#{url}> ?#{var} } ."
    end
    query = "
      SELECT DISTINCT ?parent_uri ?identifier ?publicationType ?full_reference
        ?primaryTitle ?title ?pages ?pageStart ?pageEnd ?volume ?edition
        ?publisher ?authorList ?editorList ?created ?language ?uri ?doi
        ?localityName
      WHERE {
        GRAPH ?graph {
          {
            ?parent_uri eolreference:referenceID ?reference .
            ?reference a eolreference:Reference
            #{options.join("\n")}
            FILTER (?parent_uri IN (<#{uris_to_lookup.join('>,<')}>))
          }
        }
      }"
    reference_rows = EOL::Sparql.connection.query(query)
    traits.each do |d|
      d.references = reference_rows.select{ |row| row[:parent_uri] == d.uri }
    end
  end

  def show(user)
    set_visibility(user, Visibility.visible.id)
    user_added_data.show(user) if user_added_data
  end

  def hide(user)
    set_visibility(user, Visibility.invisible.id)
    user_added_data.hide(user) if user_added_data
  end

  # TODO: This is expensive. It's eating up quite a lot of traffic on EOL.
  # Find a way to avoid it.
  def update_with_virtuoso_response(row)
    new_attributes = Trait.attributes_from_virtuoso_response(row)
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
    Trait.conversions.
      select { |c| c[:starting_units].include?(unit_known_uri.uri) }.
      each do |c|
      current_value = self.object.is_a?(RDF::Literal) ?
        self.object.value.to_f :
        self.object.to_f
      potential_new_value = c[:function].call(current_value)
      next if c[:required_minimum] && potential_new_value < c[:required_minimum]
      self.original_unit_of_measure = unit_of_measure
      self.original_unit_of_measure_known_uri = unit_of_measure_known_uri
      self.original_value = self.object
      self.object = potential_new_value
      self.unit_of_measure = c[:ending_unit].uri
      self.unit_of_measure_known_uri = c[:ending_unit]
      return true
    end
    false
  end

  # Note... this method is actually kind of view-like (something like XML
  # Builder would be ideal) and perhaps shouldn't be in this model class.
  def to_hash(language = Language.default, options = {})
    hash = if taxon_concept
             {
      # Taxon Concept ID:
      I18n.t(:data_column_tc_id) => taxon_concept_id,
      # WAIT - # Some classification context (stealing from search for now):
      # WAIT - I18n.t(:data_column_classification_summary) =>
      # taxon_concept.entry.preferred_classification_summary, Scientific Name:
      I18n.t(:data_column_sci_name) => taxon_concept.nil? ?
        '' : taxon_concept.title_canonical,
      # Common Name:
      I18n.t(:data_column_common_name) => taxon_concept.nil? ?
        '' : taxon_concept.preferred_common_name_in_language(language)
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
    hash[I18n.t(:data_column_raw_value)] = DataValue.new(original_value || object_uri).label
    # Raw Units:
    hash[I18n.t(:data_column_raw_units)] = original_units_safe(:label, default_return: nil) || units_safe(:label)
    # Raw Units URI:
    hash[I18n.t(:data_column_raw_units_uri)] = original_units_uri(default_return: nil) || units_uri
    # Source:
    hash[I18n.t(:data_column_source)] = source.try(:name) || ''
    # Resource:
    if resource
      hash[I18n.t(:data_column_resource)] =
        # Ewww. TODO - as I say at the start of the method, this really belongs in a view:
        Rails.application.routes.url_helpers.content_partner_resource_url(resource.content_partner, resource,
                                                                          host: EOL::Server.domain)
    end
    add_metadata_to_hash(hash, language)
    refs = get_references(language)
    unless refs.empty?
      hash[I18n.t(:reference)] = refs.map { |r| r[:full_reference].to_s }.join("\n")
    end
    # TODO: other measurements. ...I think.
    hash
  end

  # TODO: replace add_metadata_to_hash with add_metadata_uris_to_hash and then
  # call a method like TaxonDataSet#context_from_uris on the result; but extract
  # that into a (new) JsonLd class.
  def add_metadata_to_hash(hash, language = nil)
    language ||= Language.english
    if metadata = get_metadata(language)
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
  end

  # TODO: see #add_metadata_to_hash
  def add_metadata_uris_to_hash(hash, language = nil)
    language ||= Language.english
    if metadata = get_metadata(language)
      metadata.each do |datum|
        if hash.has_key? datum.predicate_uri
          hash[datum] = Array(hash[datum.predicate_uri]) <<
            datum.value_string(language)
        else
          hash[datum] = datum.value_string(language)
        end
      end
    end
  end

  def value_uri_or_blank
    EOL::Sparql.is_uri?(object) ? object : ''
  end

  # TODO: a lot of this stuff should be extracted to a class to handle ... this kind of stuff.  :| (DataValue, perhaps) It's
  # really very simple, but there's enough of it that it seems quite complex.
  def units_string
    units_safe(:label)
  end

  def units_uri
    units_safe(:uri)
  end

  def original_units_uri(options = {})
    original_units_safe(:uri, options)
  end

  def units_safe(attr)
    _units_safe(units, attr, options = {})
  end

  def original_units_safe(attr, options = {})
    _units_safe(original_units, attr, options)
  end

  # TODO - this logic is duplicated in the taxa helper; remove it from there. Maybe move to DataValue?
  def value_string(lang = Language.default)
    return @value_string unless @value_string.blank?
    @value_string = nil
    if association? && target_taxon_concept
      if common_name = target_taxon_concept.preferred_common_name_in_language(lang)
        @value_string = common_name
      else
        @value_string = target_taxon_concept.title_canonical
      end
    else
      val = EOL::Sparql.uri_components(object_uri)[:label].to_s # TODO - see if we need that #to_s; seems redundant.
      if val.is_numeric?
        # float values can be rounded off to 2 decimal places
        if val.is_float?
          @value_string = val.to_f.round(2)
        else
          @value_string = val.to_i
        end
      end
      # other values may have links embedded in them (references, citations, etc.)
      @value_string = val.add_missing_hyperlinks
    end
    return @value_string
  end

  # NOTE - Sadly, when using scopes here, it loads each scope for each instance, separately. (WTF?) So I'm not using scopes, I'm
  # using selects.
  def included?
    taxon_data_exemplars.select(&:included?).any?
  end

  def excluded?
    taxon_data_exemplars.select(&:excluded?).any?
  end

  # Sort by: position of known_uri, rules of exclusion, and finally value display string
  def <=>(other)
    this_position = predicate_known_uri ? (1.0 / predicate_known_uri.position) : 0
    other_position = other.predicate_known_uri ? (1.0 / other.predicate_known_uri.position) : 0
    if this_position != other_position
      other_position <=> this_position
    elsif included? && ! other.included?
      -1
    elsif other.included? && ! included?
      1
    elsif excluded? && ! other.excluded?
      1
    elsif other.excluded? && ! excluded?
      -1
    elsif value_string.is_a?(String) && ! other.value_string.is_a?(String)
      -1
    elsif other.value_string.is_a?(String) && ! value_string.is_a?(String)
      1
    else
      value_string <=> other.value_string
    end
  end

  # Grouping the results by combination of predicate and statistical method
  def grouping_factors
    group_by = [ predicate_known_uri || predicate_uri ]
    # group_by << statistical_method_label if statistical_method_label
    group_by
  end

  def statistical_method_label
    return statistical_method_known_uri.label if statistical_method_known_uri
    return statistical_method if statistical_method && !EOL::Sparql.is_uri?(statistical_method)
  end

  def life_stage_label
    return life_stage_known_uri.label if life_stage_known_uri
    return life_stage if life_stage && !EOL::Sparql.is_uri?(life_stage)
  end

  def sex_label
    return sex_known_uri.label if sex_known_uri
    return sex if sex && !EOL::Sparql.is_uri?(sex)
  end

  def context_labels
    return [ life_stage_label, sex_label ].compact
  end
  private
  def default_visibility
    self.visibility ||= Visibility.visible
  end

  def default_visibility
    self.visibility ||= Visibility.visible
  end

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

  def _units_safe(which, attr, options = {})
    options[:default_return] = '' unless options.has_key?(:default_return)
    which && which.has_key?(attr) ? which[attr] : options[:default_return]
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
        reverse_function: lambda { |v| v * 1000 },
        required_minimum: 1.0 },
      { starting_units:   [ 'http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl#C64555' ],  # decigram
        ending_unit:      KnownUri.grams.uri,
        function:         lambda { |v| v / 10 },
        reverse_function: lambda { |v| v * 10 } },
      { starting_units:   [ 'http://mimi.case.edu/ontologies/2009/1/UnitsOntology#US_pound' ],  # pound
        ending_unit:      KnownUri.grams.uri,
        function:         lambda { |v| v * 453.592 },
        reverse_function: lambda { |v| v / 453.592 } },
      { starting_units:   [ 'http://mimi.case.edu/ontologies/2009/1/UnitsOntology#US_ounce' ],  # ounce
        ending_unit:      KnownUri.grams.uri,
        function:         lambda { |v| v * 28.3495 },
        reverse_function: lambda { |v| v / 28.3495 } },
      { starting_units:   [ KnownUri.grams.uri, 'http://adw.org/g', 'http://anage.org/g' ],
        ending_unit:      KnownUri.kilograms.uri,
        function:         lambda { |v| v / 1000 },
        reverse_function: lambda { |v| v * 1000 },
        required_minimum: 1.0 },
      { starting_units:   [ KnownUri.millimeters.uri, 'http://adw.org/mm' ],
        ending_unit:      KnownUri.centimeters.uri,
        function:         lambda { |v| v / 10 },
        reverse_function: lambda { |v| v * 10 },
        required_minimum: 1.0 },
      { starting_units:   [ 'http://mimi.case.edu/ontologies/2009/1/UnitsOntology#foot' ],      # foot
        ending_unit:      KnownUri.centimeters.uri,
        function:         lambda { |v| v * 30.48 },
        reverse_function: lambda { |v| v / 30.48 } },
      { starting_units:   [ 'http://mimi.case.edu/ontologies/2009/1/UnitsOntology#inch' ],      # inch
        ending_unit:      KnownUri.centimeters.uri,
        function:         lambda { |v| v * 2.54 },
        reverse_function: lambda { |v| v / 2.54 } },
      { starting_units:   [ KnownUri.centimeters.uri ],
        ending_unit:      KnownUri.meters.uri,
        function:         lambda { |v| v / 100 },
        reverse_function: lambda { |v| v * 100 },
        required_minimum: 1.0 } ,
      { starting_units:   [ KnownUri.kelvin.uri, 'http://anage.org/k' ],
        ending_unit:      KnownUri.celsius.uri,
        function:         lambda { |v| v - 273.15 },
        reverse_function: lambda { |v| v + 273.15 } },
      { starting_units:   [ KnownUri.days.uri, 'http://anage.org/days', 'http://eol.org/schema/terms/day' ],
        ending_unit:      KnownUri.years.uri,
        function:         lambda { |v| v / 365.2425 },
        reverse_function: lambda { |v| v * 365.2425 },
        required_minimum: 0.999 },  # this is so 365 days gets converted/rounded to 1 year
      { starting_units:   [ 'http://purl.obolibrary.org/obo/UO_0000035' ],                      # months
        ending_unit:      KnownUri.years.uri,
        function:         lambda { |v| v / 12 },
        reverse_function: lambda { |v| v * 12 },
        required_minimum: 1.0 },
      { starting_units:   [ Rails.configuration.uri_term_prefix + 'onetenthdegreescelsius' ],
        ending_unit:      KnownUri.celsius.uri,
        function:         lambda { |v| v / 10 },
        reverse_function: lambda { |v| v * 10 } },
      { starting_units:   [ 'http://purl.obolibrary.org/obo/UO_0000195' ],                      # farenheight
        ending_unit:      KnownUri.celsius.uri,
        function:         lambda { |v| (((v - 32) * 5) / 9) },
        reverse_function: lambda { |v| (((v * 9) / 5) + 32) } },
      { starting_units:   [ Rails.configuration.uri_term_prefix + 'log10gram' ],
        ending_unit:      KnownUri.grams.uri,
        function:         lambda { |v| 10 ** v },
        reverse_function: lambda { |v| Math::log10(v) } },
      { starting_units:   [ Rails.configuration.uri_term_prefix + 'squareMicrometer' ],         # square micrometer
        ending_unit:      Rails.configuration.uri_obo + 'UO_0000082',                           # square millimeter
        function:         lambda { |v| v / 1000000 },
        reverse_function: lambda { |v| v * 1000000 },
        required_minimum: 1.0 },
      { starting_units:   [ Rails.configuration.uri_obo + 'UO_0000082' ],                       # square millimeter
        ending_unit:      Rails.configuration.uri_obo + 'UO_0000081',                           # square centimeter
        function:         lambda { |v| v / 100 },
        reverse_function: lambda { |v| v * 100 },
        required_minimum: 1.0 },
      { starting_units:   [ Rails.configuration.uri_obo + 'UO_0000081' ],               # square centimeter
        ending_unit:      Rails.configuration.uri_obo + 'UO_0000080',                   # square meter
        function:         lambda { |v| v / 10000 },
        reverse_function: lambda { |v| v * 10000 },
        required_minimum: 1.0 },
      { starting_units:   [ Rails.configuration.uri_obo + 'UO_0000080' ],               # square meter
        ending_unit:      Rails.configuration.uri_term_prefix + 'squarekilometer',      # square kilometer
        function:         lambda { |v| v / 1000000 },
        reverse_function: lambda { |v| v * 1000000 },
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
