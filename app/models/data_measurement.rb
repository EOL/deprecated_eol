class DataMeasurement < StructuredData

  CLASS_URI = Rails.configuration.uri_data_measurement

  def initialize(options={})
    raise 'Predicate must be a URI' unless EOL::Sparql.is_uri?(options[:predicate])
    super
    @metadata['dwc:measurementUnit'] = options[:unit] if options[:unit]
    @metadata['http://eol.org/schema/measurementOfTaxon'] = Rails.configuration.uri_true
    @uri = @graph_name + "/measurements/" + @unique_id
  end

  def turtle
    ntuple = "<#{@occurrence_uri}> a dwc:Occurrence" +
             "; dwc:taxonID <#{@taxon_uri}> . " +
             "<#{@uri}> a <#{CLASS_URI}>" +
             "; dwc:occurrenceID <#{@occurrence_uri}>" +
             "; dwc:measurementType " + EOL::Sparql.enclose_value(@predicate) +
             "; dwc:measurementValue " + EOL::Sparql.enclose_value(@object) +
             @metadata.collect{ |a,v| "; " + EOL::Sparql.enclose_value(a) + " " + EOL::Sparql.enclose_value(v) }.join(" ")
    if @taxon_name
      ntuple += ". <#{@taxon_uri}> a dwc:Taxon" +
                "; dwc:scientificName " + EOL::Sparql.enclose_value(@taxon_name)
    end
    ntuple
  end
end
