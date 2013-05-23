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
