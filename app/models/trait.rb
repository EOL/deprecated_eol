class Trait
  attr_reader :predicate, :point, :rdf

  # TODO: put these in configuration:
  SOURCE_RE = /http:\/\/eol.org\/resources\/(\d+)$/
  TAXON_RE = Rails.configuration.known_taxon_uri_re

  def initialize(rdf, page_traits)
    @rdf = rdf
    @page_traits = page_traits
    # ALL of the nodes carry the predicate, so just read any one of them:
    @predicate = rdf.first[:predicate].to_s
    # Again, they all have the "trait", sooo:
    trait_uri = rdf.first[:trait]
    @point = @page_traits.points.find { |point| point.uri == trait_uri }
  end

  def anchor
    point.anchor
  end

  def association?
    value_rdf.to_s =~ TAXON_RE
  end

  def categories
    @categories ||= predicate_uri.toc_items
  end

  def comments
    @point.comments
  end

  def content_partner
    resource && resource.content_partner
  end

  def glossary
    @page_traits.glossary
  end

  def life_stage
    # TODO
  end

  def life_stage_name
    # TODO
  end

  def partner
    resource && resource.content_partner
  end

  def predicate_name
    predicate_uri.name
  end

  def predicate_uri
    @predicate_uri ||= rdf_to_uri(@predicate)
  end

  def resource
    sources.find { |source| source.id == source_id }
  end

  def rdf_to_uri(rdf)
    uri = glossary.find { |ku| ku.uri == rdf.to_s }
    return uri if uri
    UnknownUri.new(rdf.to_s, literal: rdf.literal?)
  end

  def rdf_value(uri)
    @rdf.find { |datum| datum[:trait_predicate].to_s == uri }[:value]
  end

  def rdf_values(uri)
    @rdf.select { |datum| datum[:trait_predicate].to_s == uri }.
      map { |datum| datum[:value] }
  end

  def sex
    # TODO
  end

  def sex_name
    # TODO
  end

  def source_id
    source_url =~ SOURCE_RE ? $1.to_i : nil
  end

  def source_rdf
    rdf_value("source")
  end

  def source_url
    source_rdf.to_s
  end

  def sources
    @page_traits.sources
  end

  def statistical_method_rdfs
    rdf_values("http://eol.org/schema/terms/statisticalMethod")
  end

  def statistical_method?
    rdf_values("http://eol.org/schema/terms/statisticalMethod")
  end

  def statistical_methods
    statistical_method_rdfs.map { |rdf| rdf_to_uri(rdf) }
  end

  def statistical_method_names
    statistical_methods.map(&:name)
  end

  def value_rdf
    rdf_value("http://rs.tdwg.org/dwc/terms/measurementValue")
  end

  def value_name
    value_rdf.literal? ? value_rdf.to_s : value_uri.name
  end

  def value_uri
    @value_uri ||= rdf_to_uri(value_rdf)
  end
end
