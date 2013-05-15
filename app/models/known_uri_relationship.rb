class KnownUriRelationship < ActiveRecord::Base

  INVERSE_URI = 'http://www.w3.org/2002/07/owl#inverseOf'
  MEASUREMENT_URI = 'http://eol.org/schema/uses_measurement'

  belongs_to :from_known_uri, :class_name => KnownUri.name, :foreign_key => :from_known_uri_id
  belongs_to :to_known_uri, :class_name => KnownUri.name, :foreign_key => :to_known_uri_id

  attr_accessible :from_known_uri_id, :to_known_uri_id, :relationship_uri

  validates_uniqueness_of :to_known_uri_id, :scope => [ :from_known_uri_id, :relationship_uri ]
  validate :known_uris_should_be_known
  validate :target_should_be_measurement
  validate :subject_and_target_are_different
  validate :only_one_measurement_allowed

  after_save :update_triplestore
  after_destroy :update_triplestore

  def self.relationship_types
    { 'is inverse of' => KnownUriRelationship::INVERSE_URI,
      'has unit of measure' => KnownUriRelationship::MEASUREMENT_URI }
  end

  def relationship_label
    if type = KnownUriRelationship.relationship_types.detect{ |k,v| v == relationship_uri }
      return type[0]
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
      errors.add('to_known_uri_id', :must_be_measurement) unless to_known_uri.is_unit_of_measure?
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
