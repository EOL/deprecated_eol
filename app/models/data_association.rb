class DataAssociation < StructuredData

  CLASS_URI = Rails.configuration.uri_prefix_association

  def initialize(options={})
    raise 'Object must be a TaxonConcept' unless options[:object].is_a?(TaxonConcept)
    raise 'Type must be a URI' if options[:type] && !EOL::Sparql.is_uri?(options[:type])
    super
    @metadata['eol:associationType'] = options[:type] if options[:type]
    @uri = @graph_name + "/associations/" + @unique_id
    @target_taxon_uri = taxon_uri_for(@object)
    @target_occurrence_uri = occurrence_uri_for(@object)
  end

  def turtle
    "<#{@occurrence_uri}> a dwc:Occurrence" +
    "; dwc:taxonID <#{@taxon_uri}> . " +
    "<#{@target_occurrence_uri}> a dwc:Occurrence" +
    "; dwc:taxonID <#{@target_taxon_uri}> . " +
    "<#{@uri}> a <#{CLASS_URI}>" +
    "; dwc:occurrenceID <#{@occurrence_uri}>" +
    "; eol:targetOccurrenceID <#{@target_occurrence_uri}>" +
    @metadata.collect{ |a,v| "; " + EOL::Sparql.enclose_value(a) + " " + EOL::Sparql.enclose_value(v) }.join(" ")
  end

end
