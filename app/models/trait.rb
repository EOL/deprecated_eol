class Trait
  attr_reader :predicate, :point, :page, :rdf, :uri

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
        @page ||= @source_set.taxa[id] unless @source_set.taxa.nil?
        @page ||= TaxonConcept.find(id) unless id == 0
      end
    end
    if association?
      @inverse = false
      # "Inverted" associations have a different predicate... confusing, but true:
      if inverse?
        @predicate = inverse_association.to_s
        @inverse = true
      else
        @predicate = association.to_s
      end
    end
    make_point if @point.nil?
  end

  def inverse?
    return false unless association?
    if @page
      @page == subject_page
    elsif object_page
      @source_set.id == object_page.id
    else
      false
    end
  end

  # This keeps the output from a terminal a sane length:
  def inspect
    "<Trait @source_set_id=#{source_set_id} @predicate=#{predicate} @uri=#{uri} "\
      "@point=#{point.id} @page=#{@page} @inverse=#{inverse?}>"
  end

  def source_set_id
    @source_set.id
  end

  def anchor
    point.try(:anchor) || header_anchor
  end

  def make_point
    res_id = resource.try(:id)
    @point = DataPointUri.create(
      uri: uri.to_s,
      taxon_concept_id: @source_set.id,
      vetted_id: Vetted.trusted.id,
      visibility_id: Visibility.visible.id,
      class_type: "MeasurementOrFact",
      predicate: predicate.to_s,
      object: value_name,
      unit_of_measure: units_name,
      resource_id: res_id,
      user_added_data_id: nil,
      predicate_known_uri_id: predicate_uri.is_a?(KnownUri) ?
        predicate_uri.id : nil,
      object_known_uri_id: value_uri.is_a?(KnownUri) ? value_uri.id : nil,
      unit_of_measure_known_uri_id: units_uri.is_a?(KnownUri) ?
        units_uri.id : nil,
    )
    EOL.log("WARNING: Created missing DPURI #{uri} (#{@point.id})", prefix: "*")
    EOL.log("WARNING: That DPURI had no resource!", prefix: "*") if res_id.nil?
  end

  def header_anchor
    "trait_#{uri.gsub(/[^_A-Za-z0-9]/, '_')}"
  end

  def association
    rdf_value(TraitBank.association_uri)
  end

  def association_name
    association_uri.try(:name)
  end

  def association_uri
    rdf_to_uri(association)
  end

  def association?
    ! association.nil?
  end

  def inverse_association
    rdf_value(TraitBank.inverse_uri)
  end

  def inverse_association_name
    inverse_association_uri.try(:name)
  end

  def inverse_association_uri
    rdf_to_uri(inverse_association)
  end

  def association?
    ! association.nil?
  end

  def object_page
    @object_page ||= find_associated_taxon(TraitBank.object_page_uri)
  end

  def subject_page
    @subject_page ||= find_associated_taxon(TraitBank.subject_page_uri)
  end

  def target_taxon_name
    page = @inverse ? subject_page : object_page
    page.title_canonical_italicized
  end

  def target_taxon_uri
    "http://eol.org/pages/#{(@inverse ? subject_page : object_page).id}"
  end

  def find_associated_taxon(which)
    str = rdf_value(which).try(:to_s)
    return nil if str.nil?
    id = str.sub(TraitBank.taxon_re, "\\2")
    return nil if id.blank?
    tc = @source_set.taxa[id.to_i]
    if tc.nil?
      tc = TaxonConcept.find(id)
      tc = TaxonConcept.with_titles.find(tc)
    end
    tc
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
      # Skip association redundancies:
      next if association_redundancies.include?(pred)
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

  def association_redundancies
    @association_redundancies ||= [
      TraitBank.association_uri,
      TraitBank.inverse_uri,
      TraitBank.object_page_uri,
      TraitBank.subject_page_uri
    ]
  end

  def partner
    resource && resource.content_partner
  end
  alias :content_partner :partner

  def predicate_name
    predicate_uri.try(:name)
  end

  def predicate_group
    group = predicate_name
    if statistical_method?
      group += "/#{statistical_method_names.join("+")}"
    end
    group
  end

  def predicate_uri
    @predicate_uri ||= rdf_to_uri(@predicate)
  end

  def resource
    return @resource if @resource
    return nil if source_id.nil? || sources.nil?
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
    rdf_values(TraitBank.source_uri) + rdf_values(TraitBank.resource_uri)
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

  # NOTE: does not apply to associations (at all)
  def value_rdf
    rdf_value(TraitBank.value_uri)
  end

  def value_name
    return target_taxon_name if association?
    return "" if value_rdf.nil?
    value_uri.respond_to?(:name) ? value_uri.name  : value_rdf.to_s
  end

  def value_uri
    @value_uri ||= association? ? target_taxon_uri : rdf_to_uri(value_rdf)
  end
end
