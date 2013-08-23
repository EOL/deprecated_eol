# A curated, translated relationship between a URI and a "human-readable" string describing the intent of the URI.
# I'm going to use Curatable for now, even though vetted probably won't ever be used. ...It might be, and it makes
# this easier than splitting up that class.
class KnownUri < ActiveRecord::Base

  BASE = Rails.configuration.uri_term_prefix
  TAXON_RE = Rails.configuration.known_taxon_uri_re
  GRAPH_NAME = Rails.configuration.known_uri_graph

  include EOL::CuratableAssociation

  acts_as_list

  uses_translations

  self.per_page = 100

  belongs_to :vetted
  belongs_to :visibility
  belongs_to :uri_type

  has_many :translated_known_uris
  has_many :user_added_data
  has_many :known_uri_relationships_as_subject, :class_name => KnownUriRelationship.name, :foreign_key => :from_known_uri_id
  has_many :known_uri_relationships_as_target, :class_name => KnownUriRelationship.name, :foreign_key => :to_known_uri_id

  has_and_belongs_to_many :toc_items

  attr_accessible :uri, :visibility_id, :vetted_id, :visibility, :vetted, :translated_known_uri,
    :translated_known_uris_attributes, :toc_items, :toc_item_ids, :description, :is_unit_of_measure,
    :translations, :exclude_from_exemplars, :name

  accepts_nested_attributes_for :translated_known_uris

  validates_presence_of :uri
  validates_uniqueness_of :uri
  validate :uri_must_be_uri

  before_validation :default_values

  scope :excluded_from_exemplars, -> { where(exclude_from_exemplars: true) }

  def self.create_for_language(options = {})
    uri = KnownUri.create(uri: options.delete(:uri))
    if intent.valid?
      trans = TranslatedKnownUri.create(options.merge(known_uri: uri))
    end
    uri
  end

  def self.license
    cached_find_translated(:name, 'License')
  end

  def self.custom(name, language)
    known_uri = KnownUri.find_or_create_by_uri(BASE + EOL::Sparql.to_underscore(name))
    translated_known_uri =
      TranslatedKnownUri.where(name: name, language_id: language.id, known_uri_id: known_uri.id).first
    translated_known_uri ||= TranslatedKnownUri.create(name: name, language: language, known_uri: known_uri)
    known_uri
  end

  def self.taxon_concept_id(val)
    match = val.to_s.scan(TAXON_RE)
    if match.empty?
      false
    else
      match.first.second # Where the actual first matching group is stored.
    end
  end

  def self.unknown_uris_from_array(uris_with_counts)
    unknown_uris_with_counts = uris_with_counts
    known_uris = KnownUri.find_all_by_uri(unknown_uris_with_counts.collect{ |uri,count| uri })
    known_uris.each do |known_uri|
      unknown_uris_with_counts.delete_if{ |uri, count| known_uri.matches(uri) }
    end
    unknown_uris_with_counts
  end

  def self.group_counts_by_uri(result)
    uris_with_counts = {}
    result.each do |r|
      uri = r[:uri].to_s
      next if uri.blank?
      uris_with_counts[uri] = r[:count].to_i
    end
    uris_with_counts
  end

  # TODO - move this to Virtuoso lib.
  def self.counts_of_all_measurement_unit_uris
    result = EOL::Sparql.connection.query("SELECT ?uri, COUNT(*) as ?count
      WHERE {
        ?measurement dwc:measurementUnit ?uri .
        FILTER (isURI(?uri))
      }
      GROUP BY ?uri
      ORDER BY DESC(?count)
    ")
    group_counts_by_uri(result)
  end

  # TODO - move this to Virtuoso lib.
  def self.counts_of_all_measurement_type_uris
    result = EOL::Sparql.connection.query("SELECT ?uri, COUNT(*) as ?count
      WHERE {
        ?measurement a <#{DataMeasurement::CLASS_URI}> .
        ?measurement dwc:measurementType ?uri .
        FILTER (CONTAINS(str(?uri), '://'))
      }
      GROUP BY ?uri
      ORDER BY DESC(?count)
    ")
    group_counts_by_uri(result)
  end

  # TODO - move this to Virtuoso lib.
  def self.all_measurement_type_uris
    @@all_measurement_type_uris = Rails.cache.fetch("known_uri/all_measurement_type_urisss", :expires_in => 1.day) do
      counts_of_all_measurement_type_uris.collect{ |k,v| k }
    end
  end

  # TODO - move this to Virtuoso lib.
  def self.counts_of_all_measurement_value_uris
    result = EOL::Sparql.connection.query("SELECT ?uri, COUNT(*) as ?count
      WHERE {
        ?measurement a <#{DataMeasurement::CLASS_URI}> .
        ?measurement dwc:measurementValue ?uri .
        FILTER (CONTAINS(str(?uri), '://'))
      }
      GROUP BY ?uri
      ORDER BY DESC(?count)
    ")
    group_counts_by_uri(result)
  end

  # TODO - move this to Virtuoso lib.
  def self.counts_of_all_association_type_uris
    result = EOL::Sparql.connection.query("SELECT ?uri, COUNT(*) as ?count
      WHERE {
        ?association a <#{DataAssociation::CLASS_URI}> .
        ?association <#{Rails.configuration.uri_association_type}> ?uri .
        FILTER (CONTAINS(str(?uri), '://'))
      }
      GROUP BY ?uri
      ORDER BY DESC(?count)
    ")
    group_counts_by_uri(result)
  end

  def self.unknown_measurement_unit_uris
    unknown_uris_from_array(counts_of_all_measurement_unit_uris)
  end

  def self.unknown_measurement_type_uris
    unknown_uris_from_array(counts_of_all_measurement_type_uris)
  end

  def self.unknown_measurement_value_uris
    unknown_uris_from_array(counts_of_all_measurement_value_uris)
  end

  def self.unknown_association_type_uris
    unknown_uris_from_array(counts_of_all_association_type_uris)
  end

  def self.add_to_data(rows)
    known_uris = where(["uri in (?)", uris_in_data(rows)])
    preload_associations(known_uris, [ { :known_uri_relationships_as_subject => :to_known_uri }, { :known_uri_relationships_as_target => :from_known_uri } ])
    rows.each do |row|
      replace_with_uri(row, :attribute, known_uris)
      replace_with_uri(row, :value, known_uris)
      replace_with_uri(row, :unit_of_measure_uri, known_uris)
      if taxon_id = taxon_concept_id(row[:value])
        row[:target_taxon_concept_id] = taxon_id
      end
    end
  end

  def self.uris_in_data(rows)
    uris  = rows.map { |row| row[:attribute] }.select { |attr| attr.is_a?(RDF::URI) }
    uris += rows.map { |row| row[:value] }.select { |attr| attr.is_a?(RDF::URI) }
    uris += rows.map { |row| row[:unit_of_measure_uri] }.select { |attr| attr.is_a?(RDF::URI) }
    uris.map(&:to_s).uniq
  end

  def self.replace_with_uri(hash, key, known_uris)
    uri = known_uris.find { |known_uri| known_uri.matches(hash[key]) }
    hash[key] = uri if uri
  end

  def self.replace_taxon_concept_uris(rows)
    rows.each do |r|
      [:target_taxon_concept_id, :taxon_concept_id].each do |taxon_concept_uri_key|
        r[taxon_concept_uri_key] = KnownUri.taxon_concept_id(r[taxon_concept_uri_key]) if r.has_key?(taxon_concept_uri_key)
      end
    end
  end

  def unknown?
    name.blank?
  end

  def unit_of_measure
    if unit_of_measure_relation = known_uri_relationships_as_subject.detect{ |r| r.relationship_uri == KnownUriRelationship::MEASUREMENT_URI }
      unit_of_measure_relation.to_known_uri
    end
  end

  def matches(other_uri)
    uri.casecmp(other_uri.to_s) == 0
  end

  def add_to_triplestore
    if known_uri_relationships_as_subject
      EOL::Sparql.connection.insert_data(data: [ turtle ], graph_name: KnownUri::GRAPH_NAME)
    end
  end

  def remove_from_triplestore
    EOL::Sparql.connection.delete_uri(graph_name: KnownUri::GRAPH_NAME, uri: uri)
    EOL::Sparql.connection.query("
      DELETE FROM <#{KnownUri::GRAPH_NAME}>
      { ?s <#{KnownUriRelationship::INVERSE_URI}> <#{uri}> }
      WHERE
      { ?s <#{KnownUriRelationship::INVERSE_URI}> <#{uri}> }")
  end

  def update_triplestore
    remove_from_triplestore
    add_to_triplestore
  end

  def turtle
    statements = []
    turtle = known_uri_relationships_as_subject.each do |r|
      statements << "<#{uri}> <#{r.relationship_uri}> <#{r.to_known_uri.uri}>"
      if r.relationship_uri == KnownUriRelationship::INVERSE_URI
        statements << "<#{r.to_known_uri.uri}> <#{r.relationship_uri}> <#{uri}>"
      end
    end
    turtle = known_uri_relationships_as_target.each do |r|
      if r.relationship_uri == KnownUriRelationship::INVERSE_URI
        statements << "<#{uri}> <#{r.relationship_uri}> <#{r.from_known_uri.uri}>"
        statements << "<#{r.from_known_uri.uri}> <#{r.relationship_uri}> <#{uri}>"
      end
    end
    statements.join(" . ")
  end

  private

  def default_values
    self.vetted ||= Vetted.unknown
    self.visibility ||= Visibility.invisible # Since there are so many, we want them "not suggested", first.
  end

  def uri_must_be_uri
    errors.add('uri', :must_be_uri) unless EOL::Sparql.is_uri?(self.uri)
  end

end
