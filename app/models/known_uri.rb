# encoding: utf-8
# A curated, translated relationship between a URI and a "human-readable" string describing the intent of the URI.
# I'm going to use Curatable for now, even though vetted probably won't ever be used. ...It might be, and it makes
# this easier than splitting up that class.
#
# TODO - this class has gotten too large. Break it up. In particular, I notice there are a LOT of class methods. Perhaps that logic belongs
# elsewhere.
class KnownUri < ActiveRecord::Base

  BASE = Rails.configuration.uri_term_prefix
  TAXON_RE = Rails.configuration.known_taxon_uri_re
  GRAPH_NAME = Rails.configuration.known_uri_graph

  extend EOL::Sparql::SafeConnection # Note we ONLY need the class methods, so #extend
  extend EOL::LocalCacheable
  include EOL::CuratableAssociation

  include Enumerated
  enumerated :uri, [
    { measure:     Rails.configuration.uri_measurement_unit },
    { sex:         Rails.configuration.uri_dwc + 'sex' },
    { male:        Rails.configuration.uri_term_prefix + 'male'},
    { female:      Rails.configuration.uri_term_prefix + 'female'},
    { source:      Rails.configuration.uri_dc + 'source' },
    { license:     Rails.configuration.uri_dc + 'license' },
    { reference:   Rails.configuration.uri_dc + 'bibliographicCitation' },
    { milligrams:  Rails.configuration.uri_obo + 'UO_0000022'},
    { grams:       Rails.configuration.uri_obo + 'UO_0000021'},
    { kilograms:   Rails.configuration.uri_obo + 'UO_0000009'},
    { millimeters: Rails.configuration.uri_obo + 'UO_0000016'},
    { centimeters: Rails.configuration.uri_obo + 'UO_0000015'}, # Is 15 correct?  Or 81?
    { meters:      Rails.configuration.uri_obo + 'UO_0000008'},
    { kelvin:      Rails.configuration.uri_obo + 'UO_0000012'},
    { celsius:     Rails.configuration.uri_obo + 'UO_0000027'},
    { days:        Rails.configuration.uri_obo + 'UO_0000033'},
    { years:       Rails.configuration.uri_obo + 'UO_0000036'},
    { tenth_c:     Rails.configuration.schema_terms_prefix + 'onetenthdegreescelsius'},
    { log10_grams: Rails.configuration.schema_terms_prefix + 'log10gram'}
  ]

  acts_as_list

  uses_translations

  self.per_page = 100

  belongs_to :vetted
  belongs_to :visibility
  belongs_to :uri_type

  has_many :translated_known_uris
  has_many :user_added_data
  has_many :known_uri_relationships_as_subject, class_name: KnownUriRelationship.name, foreign_key: :from_known_uri_id,
    dependent: :destroy
  has_many :known_uri_relationships_as_target, class_name: KnownUriRelationship.name, foreign_key: :to_known_uri_id,
    dependent: :destroy

  has_and_belongs_to_many :toc_items

  attr_accessible :uri, :visibility_id, :vetted_id, :visibility, :vetted, :translated_known_uri,
    :translated_known_uris_attributes, :toc_items, :toc_item_ids, :description, :uri_type, :uri_type_id,
    :translations, :exclude_from_exemplars, :name, :known_uri_relationships_as_subject, :attribution,
    :ontology_information_url, :ontology_source_url, :position, :exemplar_for_same_as

  accepts_nested_attributes_for :translated_known_uris

  alias_attribute :label, :name

  validates_presence_of :uri
  validates_uniqueness_of :uri
  validate :uri_must_be_uri

  before_validation :default_values

  scope :excluded_from_exemplars, -> { where(exclude_from_exemplars: true) }
  scope :measurements, -> { where(uri_type_id: UriType.measurement.id) }
  scope :values, -> { where(uri_type_id: UriType.value.id) }
  scope :associations, -> { where(uri_type_id: UriType.association.id) }
  scope :metadata, -> { where(uri_type_id: UriType.metadata.id) }
  scope :visible, -> { where(visibility_id: Visibility.visible.id) }

  COMMON_URIS = [ { uri: Rails.configuration.uri_obo + 'UO_0000022', name: 'milligrams' },
                  { uri: Rails.configuration.uri_obo + 'UO_0000021', name: 'grams' },
                  { uri: Rails.configuration.uri_obo + 'UO_0000009', name: 'kilograms' },
                  { uri: Rails.configuration.uri_obo + 'UO_0000016', name: 'millimeters' },
                  { uri: Rails.configuration.uri_obo + 'UO_0000015', name: 'centimeters' },
                  { uri: Rails.configuration.uri_obo + 'UO_0000008', name: 'meters' },
                  { uri: Rails.configuration.uri_obo + 'UO_0000012', name: 'kelvin' },
                  { uri: Rails.configuration.uri_obo + 'UO_0000027', name: 'celsius' },
                  { uri: Rails.configuration.uri_obo + 'UO_0000033', name: 'days' },
                  { uri: Rails.configuration.uri_obo + 'UO_0000036', name: 'years' },
                  { uri: Rails.configuration.schema_terms_prefix + 'onetenthdegreescelsius', name: '0.1°C' },
                  { uri: Rails.configuration.schema_terms_prefix + 'log10gram', name: 'log10 grams' } ]

  # This gets called a LOT.  ...Like... a *lot* a lot. But...
  # DO NOT make a class variable and forget about it. We will need to flush the cache frequently as we
  # add/remove accepted values for UnitOfMeasure. Use the cached_with_local_timeout method
  def self.unit_of_measure
    cached_with_local_timeout('unit_of_measure') do
      KnownUri.where(uri: Rails.configuration.uri_measurement_unit).includes({ known_uri_relationships_as_subject: :to_known_uri } ).first
    end
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

  def self.add_to_data(rows)
    known_uris = where(["uri in (?)", EOL::Sparql.uris_in_data(rows)])
    preload_associations(known_uris, [ :uri_type, { known_uri_relationships_as_subject: :to_known_uri },
      { known_uri_relationships_as_target: :from_known_uri }, :toc_items ])
    rows.each do |row|
      replace_with_uri(row, :attribute, known_uris)
      replace_with_uri(row, :value, known_uris)
      replace_with_uri(row, :unit_of_measure_uri, known_uris)
      if row[:attribute].to_s == Rails.configuration.uri_association_type && taxon_id = taxon_concept_id(row[:value])
        row[:target_taxon_concept_id] = taxon_id
      end
    end
  end

  def allowed_values
    # using .select here instead of the scope .allowed_values as the scope does not work on preloaded relationships
    @allowed_values ||= known_uri_relationships_as_subject.select{ |r|
      r.relationship_uri == KnownUriRelationship::ALLOWED_VALUE_URI }.map(&:to_known_uri)
  end

  def allowed_units
    @allowed_units ||= known_uri_relationships_as_subject.select{ |r|
      r.relationship_uri == KnownUriRelationship::ALLOWED_UNIT_URI }.map(&:to_known_uri)
  end

  def has_values?
    ! allowed_values.empty?
  end

  def has_units?
    ! allowed_units.empty?
  end

  def unknown?
    name.blank?
  end

  def implied_unit_of_measure
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

  def unit_of_measure?
    # TODO - remove this first clause once unit_of_measure is added to default values.  :|
    KnownUri.unit_of_measure && KnownUri.unit_of_measure.allowed_values.include?(self)
  end

  def anchor
    uri.to_s.gsub(/[^A-Za-z0-9]/, '_')
  end

  def non_equivalence_as_subject
    known_uri_relationships_as_subject.dup.delete_if(&:same_as?)
  end

  def non_equivalence_as_target
    known_uri_relationships_as_target.dup.delete_if(&:same_as?)
  end

  def equivalence_relationships
    @equivalence_relationships ||= KnownUriRelationship.find_all_equivalence_relations_for_known_uri(id)
  end

  def indirectly_equivalent_known_uris
    # get the direct equivalence relationships
    all_equivalence_relations = equivalence_relationships
    return [] if all_equivalence_relations.empty?
    number_confirmed = 0
    confirmed_relation_ids = []
    # check each equivalent URI for things equivalent to them, until there is nothing new
    while number_confirmed < all_equivalence_relations.length
      number_confirmed = all_equivalence_relations.length
      # get the URIs from the relationship, unless they are THIS instance, or have already been looked up
      known_uri_ids_to_lookup = ( all_equivalence_relations.collect(&:from_known_uri_id) +
                                  all_equivalence_relations.collect(&:to_known_uri_id)).
                                uniq.delete_if{ |k| k == self.id || confirmed_relation_ids.include?(k) }
      unless known_uri_ids_to_lookup.empty?
        chained_equivalence_relations = KnownUriRelationship.find_all_equivalence_relations_for_known_uris(known_uri_ids_to_lookup)
        # pipe | here is for taking the union of the two arrays
        all_equivalence_relations = all_equivalence_relations | chained_equivalence_relations
        confirmed_relation_ids = confirmed_relation_ids | known_uri_ids_to_lookup
      end
    end
    ( all_equivalence_relations.collect(&:to_known_uri) +
      all_equivalence_relations.collect(&:from_known_uri)).flatten.uniq.
      delete_if{ |k| k == self || directly_equivalent_known_uris.include?(k)  }
  end

  def directly_equivalent_known_uris
    @directly_equivalent_known_uris ||=
      ( equivalence_relationships.collect(&:to_known_uri) +
        equivalence_relationships.collect(&:from_known_uri)).flatten.uniq.delete_if{ |k| k == self }
  end

  def equivalent_known_uris
    directly_equivalent_known_uris | indirectly_equivalent_known_uris
  end

  # same as the above, this just includes itself too
  def equivalence_group
    equivalent_known_uris << self
  end

  # without checking anything - blindly set this as preferred
  def set_as_exemplar_for_same_as_group
    equivalent_known_uris.each do |k|
      k.update_column(:exemplar_for_same_as, false)
    end
    update_column(:exemplar_for_same_as, true)
  end

  # use some smarts to pick a defult group representative
  def set_default_preferred_for_same_as_group
    if equivalence_group == [ self ]
      update_column(:exemplar_for_same_as, false)
    else
      count_of_preferred = equivalence_group.select(&:exemplar_for_same_as).length
      if count_of_preferred == 0
        # nothing is preferred, so just make this one preferred
        set_as_exemplar_for_same_as_group
      elsif count_of_preferred > 1
        # make the first one preferred, which will unset any other preferreds
        equivalence_group.detect(&:exemplar_for_same_as).set_as_exemplar_for_same_as_group
      end
    end
  end

  def self.search(term, options = {})
    options[:language] ||= Language.default
    return [] if term.length < 3
    TranslatedKnownUri.where(language_id: options[:language].id).
      where("name REGEXP '(^| )#{term}( |$)'").includes(:known_uri).collect(&:known_uri).compact.uniq
  end

  private

  def default_values
    self.vetted ||= Vetted.unknown
    self.visibility ||= Visibility.invisible # Since there are so many, we want them "not suggested", first.
  end

  def uri_must_be_uri
    errors.add('uri', :must_be_uri) unless EOL::Sparql.is_uri?(self.uri)
  end

  def self.replace_with_uri(hash, key, known_uris)
    uri = known_uris.find { |known_uri| known_uri.matches(hash[key]) }
    hash[key] = uri if uri
  end

end
