class Page
  # Presenter for page traits.
  class Traits
    MAX_SEARCH_DESCENDANTS = 60000
    MAX_RANGE_DESCENDANTS = 20000

    def initialize(page)
      @page = page
    end

    def scientific_name
      @page.scientific_name
    end

    def taxon_concept
      @page.taxon_concept
    end

    # Contents are where associations and their curations are stored:
    def contents
      # Another quick query that doesn't look quick:
      @page.taxon_concept.contents.traits.
        select(hierarchy_entry: { hierarchy: { resource: {
          content_partner: [:display_name]} } }).
        includes(hierarchy_entry: { hierarchy: { resource: [:content_partner] } })
    end

    # ...And this is where the traits are, based on those contents:
    def traits
      return @traits if @traits
      # NOTE: This is a VERY beefy query, but still relatively speedy:
      @traits = Traits.
        where(id: contents.map(&:item_id)).includes([:comments])
      @traits = @traits.visible unless @page.user.is_curator?
      # Inject visibility, vetted, included and excluded:
      @traits.each do |trait|
        trait.context = content.find { |content| content.item_id == trait.id }
      end
      @traits
    end

    def by_toc(toc)
      traits.find { |trait| trait.predicate.toc_items.include?(toc) }
    end

    def empty?
      traits.empty?
    end

    def ranges?
      ! ranges.empty?
    end

    def ranges
      return [] unless show_ranges?
      return @ranges if @ranges
      EOL::Sparql::Client.if_connection_fails_return([]) do
        results = SparqlQuery.ranges(taxon_concept)
        # TODO: Ensure we add the attributes and units of measure from these
        # results to the KnownUri glossary. TODO: we can't do this until we have
        # normalized units; it is neither trustworthy nor fast enough as-is.
        return @ranges = []
      end
    end

    def show_ranges?
      return false if taxon_concept.species_or_below?
      taxon_concept.number_of_descendants.between?(2, MAX_RANGE_DESCENDANTS)
    end

    def toc_items
      @toc_items ||= KnownUri.where(ids: traits.map(:predicate_id).uniq).
        includes(:translated_known_uri, toc_items: [:translated_toc_items]).
        where(["translated_known_uris.language_id = ?", @page.language_id]).
        where(["translated_toc_items.language_id = ?", @page.language_id]).
        order(:view_order)
    end

    def uris
      return @uris if @uris
      @uris = toc_items
      ids = traits.flat_map do |trait|
        [trait.inverse_id, trait.value_uri_id, trait.sex_id, trait.lifestage_id, trait.stat_method_id, trait.units_id].compact
      end
      @uris += KnownUri.where(id: ids.uniq).includes(:translated_known_uri).
        where(["translated_known_uri.language_id = ?", @page.language_id])
      @uris
    end

    # Get the name from our succinctly-loaded cache of URIs:
    def name_of_uri(uri)
      return '' if uri.nil?
      uris.find { |u| uri.id == u.i }.name
    end

    # NOTE: Only stored for associations, for obvious reasons.
    def common_names
      return @common_names if @common_names
      # This LOOKS nasty, but it actually runs REALLY fast:
      traits = traits.associations.includes(associated_to: { taxon_concept:
          { preferred_common_names: [:name] } } }).
          select(assocated_to: { taxon_concept: [ { preferred_common_names:
            { name: [:string]} } }).
          where(["taxon_concept_names.language_id = ?", @page.language_id])
      @common_names = {}
      traits.each do |trait|
        @common_names[trait.associated_to_id] =
          trait.associated_to.taxon_concept.preferred_common_names.first.name.
            string
      end
      @common_names
    end

    def name_of_association(trait)
      return '' if trait.associated_to.nil?
      c = common_names[trait.associated_to_id]
      return c || trait.associated_to.name.string
    end

    # TODO: This is a very fast query (30ms or so), but I'd still like to cache
    # it, since it doesn't make sense to do it repeatedly.
    def clade_searchable?
      @page.taxon_concept.number_of_descendants <= MAX_SEARCH_DESCENDANTS
    end

    def to_param
      @page.to_param
    end
  end
end
