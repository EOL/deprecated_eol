class StructuredData

  attr_reader :subject, :predicate, :object, :graph_name, :mappings_graph_name, :uri, :taxon_uri, :target_taxon_uri, :metadata

  def initialize(options={})
    raise 'Subject must be a TaxonConcept' unless options[:subject].is_a?(TaxonConcept)
    raise 'Resource must be an instance of class Resource' unless options[:resource].is_a?(Resource)
    @subject = options[:subject]
    @predicate = options[:predicate]
    @object = options[:object]
    @resource = options[:resource]
    @graph_name = "http://eol.org/resources/#{@resource.id}"
    @mappings_graph_name = "http://eol.org/resources/#{@resource.id}/mappings"
    @unique_id = Digest::MD5.hexdigest(self.inspect)
    @taxon_uri = taxon_uri_for(@subject)

    @metadata = {}
    options.each do |a, v|
      next if [ :subject, :predicate, :object, :resource ].include?(a)
      if EOL::Sparql.is_uri?(a)
        @metadata[a] = v
      end
    end
  end

  def update_triplestore
    remove_from_triplestore
    add_to_triplestore
  end

  def remove_from_triplestore
    sparql.delete_uri(graph_name: @graph_name, uri: @uri)
    sparql.delete_uri(graph_name: @mappings_graph_name, uri: @taxon_uri)
    sparql.delete_uri(graph_name: @mappings_graph_name, uri: @target_taxon_uri) if @target_taxon_uri
  end

  def add_to_triplestore
    sparql.insert_data(data: [ turtle ], graph_name: @graph_name)
    sparql.insert_data(data: [ mappings_turtle ], graph_name: @mappings_graph_name)
  end

  def turtle
    raise 'this method is not implemented'
  end

  def mappings_turtle
    str = "<#{@taxon_uri}> dwc:taxonConceptID <" + UserAddedData::SUBJECT_PREFIX + @subject.id.to_s + ">"
    if @target_taxon_uri
      str += ". <#{@target_taxon_uri}> dwc:taxonConceptID <" + UserAddedData::SUBJECT_PREFIX + @object.id.to_s + ">"
    end
    return str
  end

  def sparql
    @sparql ||= EOL::Sparql.connection
  end

  def taxon_uri_for(taxon_concept)
    @graph_name + "/taxa/" + Digest::MD5.hexdigest(taxon_concept.inspect)
  end
end

class DataMeasurement < StructuredData

  CLASS_URI = 'http://rs.tdwg.org/dwc/terms/MeasurementOrFact'

  def initialize(options={})
    raise 'Predicate must be a URI' unless EOL::Sparql.is_uri?(options[:predicate])
    super
    @metadata['dwc:measurementUnit'] = options[:unit] if options[:unit]
    @uri = @graph_name + "/measurements/" + @unique_id
  end

  def turtle
    "<#{@uri}> a <#{CLASS_URI}>" +
    "; dwc:taxonID <#{@taxon_uri}>" +
    "; dwc:measurementType " + EOL::Sparql.enclose_value(@predicate) +
    "; dwc:measurementValue " + EOL::Sparql.enclose_value(@object) +
    @metadata.collect{ |a,v| "; " + EOL::Sparql.enclose_value(a) + " " + EOL::Sparql.enclose_value(v) }.join(" ")
  end
end

class DataAssociation < StructuredData

  CLASS_URI = 'http://eol.org/schema/Association'

  def initialize(options={})
    raise 'Object must be a TaxonConcept' unless options[:object].is_a?(TaxonConcept)
    raise 'Type must be a URI' if options[:type] && !EOL::Sparql.is_uri?(options[:type])
    super
    @metadata['http://eol.org/schema/associationType'] = options[:type] if options[:type]
    @uri = @graph_name + "/associations/" + @unique_id
    @target_taxon_uri = taxon_uri_for(@object)
  end

  def turtle
    "<#{@uri}> a <#{CLASS_URI}>" +
    "; dwc:taxonID <#{@taxon_uri}>" +
    "; <http://eol.org/schema/targetTaxonID> <#{@target_taxon_uri}>" +
    @metadata.collect{ |a,v| "; " + EOL::Sparql.enclose_value(a) + " " + EOL::Sparql.enclose_value(v) }.join(" ")
  end
end
