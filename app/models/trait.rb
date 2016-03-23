class Trait
  attr_reader :predicate, :point, :page, :rdf, :uri

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
    @uri = rdf.first[:trait]
    @point = @source_set.points.find { |point| point.uri == @uri }
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
    point.try(:anchor) || header_anchor
  end

  def header_anchor
    "trait_#{uri.gsub(/[^_A-Za-z0-9]/, '_')}"
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

  def hidden?
    point.try(:hidden?)
  end

  def visible?
    ! hidden?
  end

  def excluded?
    point.try(:excluded?)
  end

  def included?
    point.try(:included?)
  end

  def life_stage
    rdf_value(TraitBank.life_stage_uri)
  end

  def life_stage_name
    life_stage_uri.try(:name)
  end

  def life_stage_uri
    rdf_to_uri(life_stage)
  end

  # {:predicate=>#<RDF::URI:0x44071cc(http://eol.org/schema/terms/CingulumType)>, :trait=>#<RDF::URI:0x44070f0(http://eol.org/resources/969/measurements/m1718)>, :trait_predicate=>#<RDF::URI:0x4407050(http://eol.org/schema/terms/Salinity)>, :value=>#<RDF::Literal::Integer:0x4406fd8("35"^^<http://www.w3.org/2001/XMLSchema#integer>)>}
  # {:predicate=>#<RDF::URI:0x2a11a24(http://eol.org/schema/terms/CingulumType)>, :trait=>#<RDF::URI:0x2a116c8(http://eol.org/resources/969/measurements/m1718)>, :trait_predicate=>#<RDF::URI:0x2a113f8(http://eol.org/schema/terms/SeawaterTemperature)>, :value=>#<RDF::URI:0x2a10fe8(http://eol.org/resources/969/measurements/m1730)>, :meta_predicate=>#<RDF::URI:0x2a108e0(http://rs.tdwg.org/dwc/terms/measurementUnit)>, :meta_value=>#<RDF::URI:0x2a107dc(http://purl.obolibrary.org/obo/UO_0000027)>},

  def rdf_with_meta_units
    @rdf.select { |r| r[:meta_predicate].to_s == TraitBank.value_uri }
  end

  def rdf_without_meta_units
    @rdf.select { |r| r[:meta_predicate].nil? }
  end

  def rdf_meta_units(id)
    rdf = @rdf.find { |r| r[:value].to_s == id &&
      r[:meta_predicate].to_s == TraitBank.unit_uri }
    return "[UNITS MISSING]" unless rdf
    rdf[:meta_value]
  end

  # Returns a hash of metadata. Values are always arrays, because metadata CAN
  # have one predicate with multiple values.
  def meta
    return @meta if @meta
    @meta = {}
    rdf_with_meta_units.
         each do |rdf|
      pred = rdf[:trait_predicate].to_s
      pred = glossary.find { |g| g.uri == pred } || pred
      m_units = rdf_meta_units(rdf[:value].to_s)
      m_units = glossary.find { |g| g.uri == m_units } || m_units
      val = rdf[:meta_value].to_s
      val = glossary.find { |g| g.uri == val } || val
      @meta[pred] ||= []
      @meta[pred] << { value: val, units: m_units }
    end
    rdf_without_meta_units.each do |rdf|
      pred = rdf[:trait_predicate].to_s
      # Skip type of row:
      next if pred == TraitBank.type_uri
      # Skip the value (that's already shown):
      next if pred == TraitBank.value_uri
      val = rdf[:value].to_s
      # Skip resource as "source"
      next if val =~ SOURCE_RE
      pred = glossary.find { |g| g.uri == pred } || pred
      val = glossary.find { |g| g.uri == val } || val
      @meta[pred] ||= []
      @meta[pred] << val
    end
    @meta
  end


  def meta_meta
    return @meta_meta if @meta_meta
    @meta_meta = {}
    @rdf.each do |rdf|
      next if rdf[:meta_trait].nil?
      pred = rdf[:meta_predicate].to_s
      next if pred == TraitBank.type_uri
      meta = rdf[:value].to_s
      val = rdf[:meta_value].to_s
      pred_uri = glossary.find { |g| g.uri == pred }
      val_uri = glossary.find { |g| g.uri == val }
      @meta_meta[meta] ||= []
      # NOTE: meta-metadata only allows ONE value for each predicate!
      @meta_meta[meta] << { pred_uri || pred => val_uri || val }
    end
    @meta_meta
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
    rdf_value(TraitBank.sex_uri)
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
    rdf_values(TraitBank.source_uri)
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
    rdf_values(TraitBank.statistical_method_uri)
  end

  def statistical_method?
    ! rdf_values(TraitBank.statistical_method_uri).blank?
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
    rdf_value(TraitBank.unit_uri)
  end

  def units_uri
    rdf_to_uri(units)
  end

  def units_name
    units_uri.try(:name)
  end

  def value_rdf
    rdf_value(TraitBank.value_uri)
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
