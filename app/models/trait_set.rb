class TraitSet
  A_URI = "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
  PREFIXES = {
    dc: 'http://purl.org/dc/terms/',
    dwc: 'http://rs.tdwg.org/dwc/terms/',
    eol: 'http://eol.org/schema/',
    eolterms: 'http://eol.org/schema/terms/',
    rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
    gbif: 'http://rs.gbif.org/terms/1.0/',
    foaf: 'http://xmlns.com/foaf/0.1/'
  }

  attr_accessor :points, :glossary, :traits, :sources

  # YOU *NEED* TO IMPLEMENT #initialize ! See PageTraits for an example.

  def blank?
    traits.blank?
  end

  def predicates
    @predicates ||= Set.new(traits.map(&:predicate_uri).compact).
      sort_by(&:position)
  end

  def predicate_count
    @predicate_count ||= predicates.count
  end

  def categories
    return @categories if @categories
    @categories = Set.new(traits.flat_map(&:categories)).
      to_a.sort_by(&:view_order)
    @categories
  end

  def categories_need_other?
    @need_other
  end

  # NOTE: Sorry this is complex, but: there are a lot of considerations for
  # sort!
  def traits_by_category(category)
    subset = traits.select { |trait| trait.categories.include?(category) }
    subset.sort_by do |trait|
      predicate = trait.predicate_name.try(:downcase)
      value_label = trait.value_name.try(:downcase)
      sex_sort = trait.sex_name || 255.chr
      stage_sort = trait.life_stage_name || ''
      # NOTE: it's possible to have more than one, but we only care about first:
      stats_sort = trait.statistical_method? ?
        trait.statistical_methods.first.position : 65000
      [ trait.predicate_uri.position, predicate, sex_sort,
        stats_sort, stage_sort, value_label ]
    end
  end

  # TODO: I forget whether KnownUris can be excluded from the overview. Check. I
  # don't think so (I think we rely on sort), so I haven't implemented that.
  def traits_overview
    uris = predicates[0..OverviewTraits.max_rows]
    overview = traits.select { |trait| uris.include?(trait.predicate_uri) &&
      ! trait.point.excluded? }.group_by(&:predicate_uri)
    overview.keys.each do |uri|
      overview[uri] = OverviewTraits.new(overview[uri])
    end
    overview
  end
end
