class DataMeasurement < StructuredData

  CLASS_URI = Rails.configuration.uri_data_measurement

  def initialize(options={})
    raise 'Predicate must be a URI' unless EOL::Sparql.is_uri?(options[:predicate])
    super
    @metadata['dwc:measurementUnit'] = options[:unit] if options[:unit]
    @metadata['eolterms:statisticalMethod'] = options[:statistical_method] if options[:statistical_method]
    @metadata['eolterms:normalizedValue'] = options[:normalized_value] if options[:normalized_value]
    @metadata['eolterms:normalizedUnit'] = options[:normalized_unit] if options[:normalized_unit]
    @metadata['dwc:measurementAccuracy'] = options[:accuracy] if options[:accuracy]
    @metadata['http://eol.org/schema/measurementOfTaxon'] = Rails.configuration.uri_true
    @occurrence_metadata = {}
    @occurrence_metadata['dwc:lifeStage'] =  options.delete(:life_stage) if options[:life_stage]
    @occurrence_metadata['dwc:sex'] = options.delete(:sex) if options[:sex]
    @uri = @graph_name + "/measurements/" + @unique_id
  end

  def turtle
    ntuple = "<#{@occurrence_uri}> a dwc:Occurrence" +
             "; dwc:taxonID <#{@taxon_uri}> " + 
             @occurrence_metadata.collect{ |a,v| "; " + EOL::Sparql.enclose_value(a) + " " + EOL::Sparql.enclose_value(v) }.join(" ") + " . " +
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