class UserAddedData < ActiveRecord::Base

  GRAPH_NAME = Rails.configuration.user_added_data_graph
  URI_REGEX = /#{GRAPH_NAME.sub('/', '\\/')}(\d+)$/

  include EOL::CuratableAssociation

  attr_accessible :subject, :subject_type, :subject_id, :user, :user_id, :predicate, :object,
    :user_added_data_metadata_attributes, :deleted_at, :visibility, :visibility_id, :vetted,
    :vetted_id, :predicate_known_uri_id, :object_known_uri_id, :has_values

  attr_accessor :predicate_known_uri_id
  attr_accessor :object_known_uri_id
  attr_accessor :has_values

  belongs_to :subject, polymorphic: true
  belongs_to :user
  belongs_to :vetted
  belongs_to :visibility

  has_one :data_point_uri

  has_many :comments, as: :parent
  has_many :all_comments, as: :parent, class_name: 'Comment'
  has_many :user_added_data_metadata, class_name: "UserAddedDataMetadata"
  has_many :taxon_data_exemplars, as: :parent

  validates_presence_of :user_id, :subject, :predicate, :object
  validate :predicate_must_be_uri
  validate :expand_and_validate_namespaces # Without this, the validation on namespaces doesn't run.

  before_validation :convert_known_uris

  after_create :update_triplestore
  after_create :create_data_point_uri
  after_update :update_data_point_uri
  after_update :update_triplestore

  accepts_nested_attributes_for :user_added_data_metadata, allow_destroy: true

  def self.from_value(value)
    if value && matches = value.to_s.match(URI_REGEX)
      return nil unless UserAddedData.exists?(matches[1])
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
    raise NotImplementedError unless subject.is_a?(TaxonConcept)
    "<#{uri}> a <#{DataMeasurement::CLASS_URI}>" +
      # TODO - this needs to be dynamic:
    "; dwc:taxonConceptID <" + SparqlQuery::TAXON_PREFIX + subject.id.to_s + ">" +
    "; dwc:measurementType " + EOL::Sparql.enclose_value(predicate) +
    "; dwc:measurementValue " + EOL::Sparql.enclose_value(object) +
    "; eol:measurementOfTaxon eolterms:true"
  end

  # Needed when commentable:
  def summary_name
    # TODO ... something useful here
    "#{predicate} => #{object} for #{subject_type} #{subject_id}"
  end

  def anchor
    "user_added_data_#{id}"
  end

  def predicate_label
    EOL::Sparql.uri_components(predicate)[:label]
  end

  private

  def is_taxon_uri?(uri)
    KnownUri.taxon_concept_id(uri)
  end

  def convert_known_uris
    if self.predicate_known_uri_id && known_uri = KnownUri.find_by_id(self.predicate_known_uri_id)
      self.predicate = known_uri.uri
    else
      self.predicate = convert_known_uri(self.predicate) unless EOL::Sparql.is_uri?(self.predicate)
    end
    if self.object_known_uri_id && known_uri = KnownUri.find_by_id(self.object_known_uri_id)
      self.object = known_uri.uri
    else
      self.object = convert_known_uri(self.object) unless EOL::Sparql.is_uri?(self.predicate)
    end
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

  def create_data_point_uri
    # TODO: set unit_of_measure
    DataPointUri.create(
      uri: uri,
      taxon_concept_id: taxon_concept_id,
      class_type: 'MeasurementOrFact',
      user_added_data_id: id,
      vetted_id: vetted_id,
      visibility_id: visibility_id,
      predicate: predicate,
      object: object,
      unit_of_measure: nil )
  end

  def update_data_point_uri
    # TODO: set unit_of_measure
    data_point_uri.vetted_id = vetted_id
    data_point_uri.visibility_id = visibility_id
    data_point_uri.predicate = predicate
    data_point_uri.object = object
    data_point_uri.unit_of_measure = nil
    data_point_uri.save
  end

  def notification_recipient_objects()
    return @notification_recipients if @notification_recipients
    @notification_recipients = []
    add_recipient_user(@notification_recipients)
    add_recipient_pages_affected(@notification_recipients)
    add_recipient_users_watching(@notification_recipients)
    @notification_recipients
  end

  def queue_notifications
    Notification.queue_notifications(notification_recipient_objects, self)
  end

  def add_recipient_user(recipients)
    recipients << { user: user, notification_type: :i_created_something,
                    frequency: NotificationFrequency.never }
    recipients << user.watch_collection if user.watch_collection
  end

  def add_recipient_pages_affected(recipients)
    if taxon_concept
      recipients << taxon_concept
      recipients << { ancestor_ids: taxon_concept.flattened_ancestor_ids }
    end
  end

  def add_recipient_users_watching(recipients)
    if taxon_concept
      taxon_concept.containing_collections.watch.each do |collection|
        collection.users.each do |user|
          user.add_as_recipient_if_listening_to(:new_data_on_my_watched_item, recipients)
        end
      end
    end
  end
end
