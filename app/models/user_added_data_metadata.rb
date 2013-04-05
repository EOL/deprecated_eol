class UserAddedDataMetadata < ActiveRecord::Base

  belongs_to :user_added_data

  after_create :add_to_triplestore
  after_update :add_to_triplestore
  before_destroy :remove_from_triplestore

  validates_presence_of :predicate, :object
  validate :predicate_must_be_uri
  validate :expand_and_validate_namespaces # Without this, the validation on namespaces doesn't run.

  def turtle
    "<#{user_added_data.uri}> " + EOL::Sparql.enclose_value(predicate) + " " + EOL::Sparql.enclose_value(object)
  end

  def add_to_triplestore
    sparql.insert_data(data: [turtle], graph_name: UserAddedData::GRAPH_NAME)
  end

  def remove_from_triplestore
    sparql.delete_data(graph_name: UserAddedData::GRAPH_NAME, data: turtle)
  end

  private

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
