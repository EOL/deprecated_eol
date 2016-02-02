class Trait
  attr_reader :predicate, :point, :rdf, :page

  # TODO: put this in configuration:
  SOURCE_RE = TraitBank::SOURCE_RE

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

  def glossary
    @source_set.glossary
  end

  def life_stage
    rdf_value("http://rs.tdwg.org/dwc/terms/lifeStage")
  end

  def life_stage_name
    life_stage_uri.try(:name)
  end

  def life_stage_uri
    rdf_to_uri(life_stage)
  end

  def meta
    return @meta if @meta
    @meta = {}
    @rdf.each do |rdf|
      pred = rdf[:trait_predicate].to_s
      val = rdf[:value].to_s
      # Skip type of row:
      next if pred == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
      # Skip the value (that's already shown):
      next if pred == "http://rs.tdwg.org/dwc/terms/measurementValue"
      # Skip resource as "source"
      next if val =~ SOURCE_RE
      pred_uri = glossary.find { |g| g.uri == pred }
      val_uri = glossary.find { |g| g.uri == val }
      @meta[pred_uri || pred] = val_uri || val
    end
    @meta
  end

  def partner
    resource && resource.content_partner
  end
  alias :content_partner :partner

  def predicate_name
    predicate_uri.try(:name)
  end

  def predicate_uri
    @predicate_uri ||= rdf_to_uri(@predicate)
  end

  def resource
    return @resource if @resource
    return nil if source_id.nil?
    @resource = sources.find { |source| source.id == source_id }
    if @resource.nil?
      EOL.log("JIT-loading resource #{source_id} (this is not good)")
      @resource = Resource.where(id: source_id).includes(:content_partner).first
      sources += @resource if sources && @resource
    end
    @resource
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
    sex_uri.try(:name)
  end

  def sex_uri
    rdf_to_uri(sex)
  end

  def source_id
    @source_id ||= source_url =~ SOURCE_RE ? $1.to_i : nil
  end

  def all_source_rdfs
    rdf_values("http://purl.org/dc/terms/source")
  end

  def other_sources
    all_source_rdfs.select { |r| r.to_s !~ TraitBank::SOURCE_RE }.map(&:to_s)
  end

  def source_rdf
    rdf = all_source_rdfs.find { |r| r.to_s =~ TraitBank::SOURCE_RE }
    # Old resources were stored as "source":
    unless rdf
      take_two = rdf_value("source")
      rdf = take_two if take_two =~ SOURCE_RE
    end
    rdf
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

  def to_hash
    TraitBank::ToHash.from(self)
  end

  def units?
    units
  end

  def units
    rdf_value("http://rs.tdwg.org/dwc/terms/measurementUnit")
  end

  def units_uri
    rdf_to_uri(units)
  end

  def units_name
    units_uri.try(:name)
  end

  def value_rdf
    rdf_value("http://rs.tdwg.org/dwc/terms/measurementValue")
  end

  def value_name
    #TODO: associations. :\
    return "" if value_rdf.nil?
    value_uri.respond_to?(:name) ? value_uri.name  : value_rdf.to_s
  end

  def value_uri
    @value_uri ||= rdf_to_uri(value_rdf)
  end
end
