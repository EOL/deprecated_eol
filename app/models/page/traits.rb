class Page
  # Presenter for page traits.
  class Traits
    MAXIMUM_DESCENDANTS_FOR_CLADE_SEARCH = 60000

    def initialize(page)
      @page = page
    end

    def scientific_name
      @page.scientific_name
    end

    def taxon_concept
      @page.taxon_concept
    end

    def traits
      # This is a VERY beefy query, but still relatively speedy:
      @page.taxon_concept.traits.with_uris.includes([:comments])
    end

    def by_toc(toc)
      return @traits if @traits
      @traits = traits.find { |trait| trait.predicate.toc_items.include?(toc) }
      @traits = @traits.visible unless @page.user.is_curator?
    end

    def empty?
      traits.empty?
    end

    def ranges?
      ! ranges.empty?
    end

    def ranges
      # TODO
    end

    def toc_items
      @toc_items ||= traits.map(&:predicate).uniq.sort_by(&:view_order)
    end

    def glossary
      ! glossary.empty?
    end

    def glossary
      # TODO
    end

    # TODO: This is a very fast query (30ms or so), but I'd still like to cache
    # it, since it doesn't make sense to do it repeatedly.
    def clade_searchable?
      @page.taxon_concept.number_of_descendants <=
        MAXIMUM_DESCENDANTS_FOR_CLADE_SEARCH
    end

    def to_param
      @page.to_param
    end
  end
end
