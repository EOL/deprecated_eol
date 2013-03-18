class UserAddedData < ActiveRecord::Base

  BASIC_URI_REGEX = /^http:\/\/[^ ]+$/i
  ENCLOSED_URI_REGEX = /^<http:\/\/[^ ]+>$/i
  NAMESPACED_URI_REGEX = /^([a-z0-9_-]{1,30}):(.*)$/i

  attr_accessor :graph_name

  belongs_to :user

  validates_presence_of :user_id
  validates_presence_of :subject
  validates_presence_of :predicate
  validates_presence_of :object
  validate :subject_must_be_uri
  validate :predicate_must_be_uri

  before_create :expand_namespaces
  after_create :add_to_triplestore
  before_destroy :remove_from_triplestore

  def self.graph_name
    "http://eol.org/user_data/"
  end

  def subject_must_be_uri
    errors.add('subject', "Subject must be a URI") unless self.class.is_uri?(self.subject)
  end

  def predicate_must_be_uri
    errors.add('predicate', "Predicate must be a URI") unless self.class.is_uri?(self.predicate)
  end

  def expand_namespaces
    str = self.class.prepare_value_for_sparql(self.subject)
    if str === false
      errors.add('subject', "Unknown namespace")
      return false
    end
    self.subject = str

    str = self.class.prepare_value_for_sparql(self.predicate)
    if str === false
      errors.add('predicate', "Unknown namespace")
      return false
    end
    self.predicate = str

    str = self.class.prepare_value_for_sparql(self.object)
    if str === false
      errors.add('object', "Unknown namespace")
      return false
    end
    self.object = str
  end

  def add_to_triplestore
    begin
      EOL::Sparql.connection.insert_data(
        :data => [ turtle ],
        :graph_name => self.class.graph_name)
    rescue
      return false
    end
  end

  def remove_from_triplestore
    begin
      EOL::Sparql.connection.sparql_update("DELETE DATA { GRAPH <#{self.class.graph_name}> { #{turtle} } }")
    rescue
      return false
    end
  end

  def turtle
    "<#{self.class.graph_name}#{id}> a dwc:MeasurementOrFact" +
    "; <http://rs.tdwg.org/dwc/terms/taxonConceptID> " + subject +
    "; <http://rs.tdwg.org/dwc/terms/measurementType> " + predicate +
    "; <http://rs.tdwg.org/dwc/terms/measurementValue> " + object
  end

  def self.prepare_value_for_sparql(uri_namespace_or_literal)
    if uri_namespace_or_literal =~ BASIC_URI_REGEX                              # full URI
      return "<" + uri_namespace_or_literal + ">"
    elsif uri_namespace_or_literal =~ ENCLOSED_URI_REGEX                        # full URI
      return uri_namespace_or_literal
    elsif matches = uri_namespace_or_literal.match(NAMESPACED_URI_REGEX)        # namespace
      if full_uri = EOL::Sparql.common_namespaces[matches[1]]
        return "<" + full_uri + matches[2] + ">"
      else
        return false  # this is the failure - an unknown namespace was given
      end
    else                                                                        # literal value
      uri_namespace_or_literal = '"' + uri_namespace_or_literal + '"'
    end
  end

  def self.is_uri?(string)
    return true if string =~ BASIC_URI_REGEX
    return true if string =~ ENCLOSED_URI_REGEX
    return true if string =~ NAMESPACED_URI_REGEX
    false
  end

  def self.recreate_triplestore_graph
    EOL::Sparql.connection.delete_graph(graph_name)
    begin
      EOL::Sparql.connection.insert_data(
        :data => UserAddedData.all.collect{ |d| d.turtle },
        :graph_name => graph_name)
    rescue
      return false
    end
  end
end
