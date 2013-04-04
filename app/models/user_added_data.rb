class UserAddedData < ActiveRecord::Base

  SUBJECT_PREFIX = "http://eol.org/pages/" # TODO - this should probably be configurable.
  GRAPH_NAME = "http://eol.org/user_data/" # TODO - this too. :)
  URI_REGEX = /#{GRAPH_NAME.sub('/', '\\/')}(\d+)$/

  # The Subject should probably point to a taxon_concept, so we allow you to specify one:
  attr_accessor :taxon_concept_id

  belongs_to :user

  validates_presence_of :user_id
  validates_presence_of :subject
  validates_presence_of :predicate
  validates_presence_of :object
  validate :subject_must_be_uri
  validate :predicate_must_be_uri
  validate :expand_namespaces # Without this, the validation on namespaces doesn't run.

  before_validation :turn_taxon_concept_id_into_subject
  before_create :expand_namespaces
  before_destroy :remove_from_triplestore

  after_create :add_to_triplestore

  # TODO - this is just for testing. You really don't want to run this in production...
  def self.recreate_triplestore_graph
    sparql = EOL::Sparql.connection
    sparql.delete_graph(GRAPH_NAME)
    begin
      sparql.insert_data(
        :data => UserAddedData.all.map(&:turtle),
        :graph_name => GRAPH_NAME)
    rescue
      return false
    end
  end

  def add_to_triplestore
    begin
      sparql.insert_data(data: [turtle], graph_name: GRAPH_NAME)
    rescue
      return false
    end
  end

  def remove_from_triplestore
    begin
      sparql.delete_data(data: turtle, graph_name: GRAPH_NAME)
    rescue
      return false
    end
  end

  def turtle
    %(<#{GRAPH_NAME}#{id}> a dwc:MeasurementOrFact
    ; <http://rs.tdwg.org/dwc/terms/taxonConceptID> #{subject}
    ; <http://rs.tdwg.org/dwc/terms/measurementType> #{predicate}
    ; <http://rs.tdwg.org/dwc/terms/measurementValue> #{object})
  end

  private

  def sparql
    @sparql ||= EOL::Sparql.connection
  end

  def subject_must_be_uri
    errors.add('subject', :must_be_uri) unless EOL::Sparql.is_uri?(self.subject)
  end

  def predicate_must_be_uri
    errors.add('predicate', :must_be_uri) unless EOL::Sparql.is_uri?(self.predicate)
  end

  def expand_namespaces
    return if @already_expanded
    str = EOL::Sparql.prepare_value(self.subject)
    if str === false
      errors.add('subject', :namespace)
      return false
    end
    self.subject = str

    str = EOL::Sparql.prepare_value(self.predicate)
    if str === false
      errors.add('predicate', :namespace)
      return false
    end
    self.predicate = str

    str = EOL::Sparql.prepare_value(self.object)
    if str === false
      errors.add('object', :namespace)
      return false
    end
    self.object = str
    @already_expanded = true
  end

  def turn_taxon_concept_id_into_subject
    self.subject = "<#{SUBJECT_PREFIX}#{self.taxon_concept_id}>" if self.taxon_concept_id
  end

end
