class KnownUriRelationship < ActiveRecord::Base

  INVERSE_URI = Rails.configuration.uri_inverse
  MEASUREMENT_URI = Rails.configuration.uri_uses_measurement
  ALLOWED_VALUE_URI = Rails.configuration.uri_allowed_val
  ALLOWED_UNIT_URI = Rails.configuration.uri_allowed_unit

  belongs_to :from_known_uri, :class_name => 'KnownUri', :foreign_key => :from_known_uri_id
  belongs_to :to_known_uri, :class_name => 'KnownUri', :foreign_key => :to_known_uri_id

  attr_accessible :from_known_uri, :from_known_uri_id, :to_known_uri, :to_known_uri_id, :relationship_uri

  validates_uniqueness_of :to_known_uri_id, :scope => [ :from_known_uri_id, :relationship_uri ]
  validate :known_uris_should_be_known
  validate :target_should_be_measurement
  validate :subject_and_target_are_different
  validate :only_one_measurement_allowed

  after_save :update_triplestore
  after_destroy :update_triplestore

  scope :inverses, -> { where(relationship_uri: KnownUriRelationship::INVERSE_URI) }
  scope :allowed_values, -> { where(relationship_uri: KnownUriRelationship::ALLOWED_VALUE_URI) }
  scope :allowed_units, -> { where(relationship_uri: KnownUriRelationship::ALLOWED_UNIT_URI) }

  # NOTE - The keys here are I18n keys and need translations.
  @relationship_types =
    { :known_uri_label_inverse => KnownUriRelationship::INVERSE_URI,
      :known_uri_label_allowed_val => KnownUriRelationship::ALLOWED_VALUE_URI,
      :known_uri_label_allowed_unit => KnownUriRelationship::ALLOWED_UNIT_URI,
      :known_uri_label_unit => KnownUriRelationship::MEASUREMENT_URI }

  def self.create_defaults
    { KnownUri.unit_of_measure =>
      [ KnownUri.milligrams,
        KnownUri.grams,
        KnownUri.kilograms,
        KnownUri.millimeters,
        KnownUri.centimeters,
        KnownUri.meters,
        KnownUri.kelvin,
        KnownUri.celsius,
        KnownUri.days,
        KnownUri.years,
        KnownUri.tenth_C,
        KnownUri.log10_grams],
      KnownUri.sex => [ KnownUri.male, KnownUri.female ] # TODO - REALLY, this shouldn't be a default, but in a scenario.
    }.each do |parent, values|
      values.each do |value|
        KnownUriRelationship.create(from_known_uri: parent, to_known_uri: value, relationship_uri: ALLOWED_VALUE_URI)
      end
    end
  end

  def self.relationship_types
    @relationship_types
  end

  def self.translated_relationship_types
    translations = @relationship_types.dup
    Hash[translations.map {|k, v| [I18n.t(k), v] }]
  end

  def relationship_label
    if type = KnownUriRelationship.relationship_types.detect { |k,v| v == relationship_uri }
      return I18n.t(type[0])
    end
  end

  def update_triplestore
    from_known_uri.update_triplestore if from_known_uri
    to_known_uri.update_triplestore if to_known_uri
  end

  private

  def known_uris_should_be_known
    errors.add('from_known_uri_id', :must_be_known_uri) unless from_known_uri
    errors.add('to_known_uri_id', :must_be_known_uri) unless to_known_uri
  end

  def target_should_be_measurement
    if relationship_uri == KnownUriRelationship::MEASUREMENT_URI
      errors.add('to_known_uri_id', :must_be_measurement) unless to_known_uri.unit_of_measure?
    end
  end

  def subject_and_target_are_different
    errors.add('to_known_uri_id', :must_be_different) if from_known_uri_id == to_known_uri_id
  end

  def only_one_measurement_allowed
    if relationship_uri == KnownUriRelationship::MEASUREMENT_URI
      if from_known_uri.known_uri_relationships_as_subject.where(:relationship_uri => KnownUriRelationship::MEASUREMENT_URI).count > 0
        errors.add('relationship_uri', :only_one_measurement)
      end
    end
  end
end
