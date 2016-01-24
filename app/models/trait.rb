class Trait
  attr_reader :predicate, :point, :rdf, :page

  # TODO: put this in configuration:
  SOURCE_RE = /http:\/\/eol.org\/resources\/(\d+)$/

  def initialize(rdf, source_set, options = {})
    @rdf = rdf
    @source_set = source_set
    if options.has_key?(:predicate)
      @predicate = options[:predicate]
    else
      # ALL of the nodes carry the predicate, so just read any one of them:
      @predicate = rdf.first[:predicate].to_s
    end
    # Again, they all have the "trait", sooo:
    trait_uri = rdf.first[:trait]
    @point = @source_set.points.find { |point| point.uri == trait_uri }
    if rdf.first.has_key?(:page)
      # If there's a page, they all have it:
      if rdf.first[:page].to_s =~ TraitBank.taxon_re
        id = $2.to_i
        @page = options[:taxa].find { |taxon| taxon.id == id }
        @page ||= TaxonConcept.find(id) unless id == 0
      end
    end
  end

  def anchor
    point.anchor
  end

  def association?
    value_rdf.to_s =~ TraitBank.taxon_re
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
    @source_set.glossary
  end

  def life_stage
    rdf_value("http://rs.tdwg.org/dwc/terms/lifeStage")
  end

  def life_stage_name
    life_stage_uri.name
  end

  def life_stage_uri
    rdf_to_uri(life_stage)
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
    return nil if rdf.nil?
    uri = glossary.find { |ku| ku.uri == rdf.to_s }
    return uri if uri
    literal = rdf.respond_to?(:literal?) ? rdf.literal? : true
    UnknownUri.new(rdf.to_s, literal: literal)
  end

  def rdf_value(uri)
    rdf = @rdf.find { |datum| datum[:trait_predicate].to_s == uri }
    rdf ? rdf[:value] : nil
  end

  def rdf_values(uri)
    @rdf.select { |datum| datum[:trait_predicate].to_s == uri }.
      map { |datum| datum[:value] }
  end

  def sex
    rdf_value("http://rs.tdwg.org/dwc/terms/sex")
  end

  def sex_name
    sex.try(:name)
  end

  def source_id
    source_url =~ SOURCE_RE ? $1.to_i : nil
  end

  def source_rdf
    return @source_rdf if @source_rdf
    @source_rdf = rdf_value("http://purl.org/dc/terms/source")
    # Old resources were stored as "source":
    unless @source_rdf =~ SOURCE_RE
      take_two = rdf_value("source")
      @source_rdf = take_two if take_two =~ SOURCE_RE
    end
  end

  def source_url
    source_rdf.to_s
  end

  def sources
    @source_set.sources
  end

  def statistical_method_rdfs
    rdf_values("http://eol.org/schema/terms/statisticalMethod")
  end

  def statistical_method?
    ! rdf_values("http://eol.org/schema/terms/statisticalMethod").blank?
  end

  def statistical_methods
    statistical_method_rdfs.map { |rdf| rdf_to_uri(rdf) }
  end

  def statistical_method_names
    statistical_methods.map(&:name)
  end

  #TODO: associations.  :\
  def target_taxon_name
    "TODO: association"
  end

  def target_taxon_uri
    "http://eol.org/todo"
  end

  def value_rdf
    rdf_value("http://rs.tdwg.org/dwc/terms/measurementValue")
  end

  def value_name
    #TODO: associations.  :\
    return nil if value_rdf.nil?
    value_rdf.literal? ? value_rdf.to_s : value_uri.name
  end

  def value_uri
    @value_uri ||= rdf_to_uri(value_rdf)
  end
end
