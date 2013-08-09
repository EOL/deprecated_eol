class UserAddedData < ActiveRecord::Base

  SUBJECT_PREFIX = "http://eol.org/pages/" # TODO - this should probably be configurable. ...And polymorphic, so a hash. :|
  GRAPH_NAME = "http://eol.org/user_data/" # TODO - this too. :)
  URI_REGEX = /#{GRAPH_NAME.sub('/', '\\/')}(\d+)$/

  include EOL::CuratableAssociation

  belongs_to :subject, :polymorphic => true
  belongs_to :user
  belongs_to :vetted
  belongs_to :visibility
  
  has_many :comments, :as => :parent
  has_many :all_comments, :as => :parent, :class_name => 'Comment'
  has_many :user_added_data_metadata, :class_name => "UserAddedDataMetadata"
  has_many :taxon_data_exemplars, as: :parent

  validates_presence_of :user_id, :subject, :predicate, :object
  validate :predicate_must_be_uri
  validate :expand_and_validate_namespaces # Without this, the validation on namespaces doesn't run.

  before_validation :convert_known_uris

  after_create :update_triplestore
  after_update :update_triplestore

  attr_accessible :subject, :subject_type, :subject_id, :user, :user_id, :predicate, :object, :user_added_data_metadata_attributes, :deleted_at,
    :visibility, :visibility_id, :vetted, :vetted_id

  accepts_nested_attributes_for :user_added_data_metadata, :allow_destroy => true

  def self.from_value(value)
    if value && matches = value.to_s.match(URI_REGEX)
      uad = UserAddedData.find(matches[1])
      return uad if uad
    end
    nil
  end

  def can_be_updated_by?(user_wanting_access)
    user == user_wanting_access || user_wanting_access.is_admin?
  end
  def can_be_deleted_by?(user_wanting_access)
    user == user_wanting_access || user_wanting_access.is_admin?
  end

  def add_to_triplestore
    unless deleted_at
      target = is_taxon_uri?(object)
      if target && TaxonConcept.exists?(target.to_i)
        target = TaxonConcept.find(target.to_i)
        DataAssociation.new(metadata: user_added_data_metadata, subject: subject,
                            graph_name: GRAPH_NAME, object: target).add_to_triplestore
      else
        sparql.insert_data(data: [turtle], graph_name: GRAPH_NAME)
        user_added_data_metadata.each do |metadata|
          sparql.insert_data(data: [metadata.turtle], graph_name: GRAPH_NAME)
        end
      end
    end
  end

  def update_triplestore
    remove_from_triplestore
    add_to_triplestore
  end

  def remove_from_triplestore
    sparql.delete_uri(graph_name: GRAPH_NAME, uri: uri)
  end

  def taxon_concept
    return subject if subject.is_a?(TaxonConcept)
  end

  def taxon_concept_id
    return subject.id if subject.is_a?(TaxonConcept)
  end

  def uri
    GRAPH_NAME + id.to_s
  end

  def turtle
    raise NotImlementedError unless subject.is_a?(TaxonConcept)
    "<#{uri}> a <#{DataMeasurement::CLASS_URI}>" +
      # TODO - this needs to be dynamic:
    "; dwc:taxonConceptID <" + UserAddedData::SUBJECT_PREFIX + subject.id.to_s + ">" +
    "; dwc:measurementType " + EOL::Sparql.enclose_value(predicate) +
    "; dwc:measurementValue " + EOL::Sparql.enclose_value(object)
  end

  # Needed when commentable:
  def summary_name
    # TODO ... something useful here
    "#{predicate} => #{value} for #{subject_type} #{subject_id}"
  end

  def anchor
    "user_added_data_#{id}"
  end

  private

  def is_taxon_uri?(uri)
    KnownUri.taxon_concept_id(uri)
  end

  def convert_known_uris
    self.predicate = convert_known_uri(self.predicate) unless EOL::Sparql.is_uri?(self.predicate)
    self.object = convert_known_uri(self.object) unless EOL::Sparql.is_uri?(self.predicate)
  end

  def convert_known_uri(which)
    tku = TranslatedKnownUri.find_by_name(which)
    return tku ? tku.known_uri.uri : which
  end

  def sparql
    @sparql ||= EOL::Sparql.connection
  end

  def predicate_must_be_uri
    errors.add('predicate', :must_be_uri) unless EOL::Sparql.is_uri?(self.predicate)
  end

  def expand_and_validate_namespaces
    return if @already_expanded
    str = EOL::Sparql.expand_namespaces(self.predicate)
    if str === false
      errors.add('predicate', :namespace)
      return false
    end
    self.predicate = str

    str = EOL::Sparql.expand_namespaces(self.object)
    if str === false
      errors.add('object', :namespace)
      return false
    end
    self.object = str
    @already_expanded = true
  end

end
