class SearchTraits < TraitSet
  attr_accessor :pages, :page, :attribute

  def self.warm
    EOL.log_call
    preds = TraitBank.predicates
    preds.each do |p|
      r = SearchTraits.new(attribute: p[1])
      EOL.log("#{r.traits.count} results for #{p[1]} (#{p[2]})")
    end
  end

  # e.g.: @traits = SearchTraits.new(attribute: "http://purl.obolibrary.org/obo/OBA_0000056")

  # e.g.: s = SearchTraits.new(attribute: "http://purl.obolibrary.org/obo/OBA_0000056")

  # search_options = { querystring: @querystring, attribute: @attribute,
    # min_value: @min_value, max_value: @max_value, page: @page,
    # per_page: @per_page, unit: @unit, sort: @sort, language: current_language,
    # clade: @taxon_concept.id,
    # required_equivalent_attributes: @required_equivalent_attributes,
    # required_equivalent_values: @required_equivalent_values }
  def initialize(search_options)
    @attribute = search_options[:attribute]
    @page = search_options[:page] || 1
    @per_page = search_options[:per_page] || 100
    # NOTE ********************* IMPORTANT  !!!!! **********************
    # If you make changes to search, you MUST consider any necessary changes to
    # the cache key!!!
    if @attribute.blank?
      @rdf = []
      @pages = []
      @points = []
      @glossary = []
      @sources = []
      @traits = [].paginate
    else
      @key = "trait_bank/search/#{@attribute.gsub(/\W/, '_')}"
      @key += "/page/#{@page}" unless @page == 1
      @key += "/per/#{@per_page}" unless @per_page == 100
      @key += "/clade/#{search_options[:clade]}" unless
        search_options[:clade].blank?
      @key += "/desc" if search_options[:sort] =~ /^desc$/i
      # TODO: some of this could be generalized into TraitSet.
      @rdf = TraitBank.cache_query(@key) do
        TraitBank::Scan.for(search_options)
      end
      @pages = get_pages(@rdf.map { |trait| trait[:page].to_s })
      trait_uris = Set.new(@rdf.map { |trait| trait[:trait] })
      @points = DataPointUri.where(uri: trait_uris.to_a.map(&:to_s)).
        includes(:comments, :taxon_data_exemplars)
      uris = Set.new(@rdf.flat_map { |rdf|
        rdf.values.select { |v| EOL::Sparql.is_uri?(v.to_s) } })
      uris << @attribute
      # TODO: associations. We need the names of those taxa.
      @glossary = KnownUri.where(uri: uris.to_a.map(&:to_s)).
        includes(toc_items: :translated_toc_items)
      rdf_by_trait = @rdf.group_by { |trait| trait[:trait] }
      traits = rdf_by_trait.keys.map do |trait|
        Trait.new(rdf_by_trait[trait], self, taxa: @pages,
          predicate: @attribute)
      end
      total = if traits.count >= @per_page || @page > 1
        Rails.cache.fetch(@key.sub('search', 'search/count'), expires_in: 1.day) do
          TraitBank::Scan.trait_count(search_options)
        end
      else
        traits.count
      end
      @traits = WillPaginate::Collection.create(@page, @per_page, total) do |pager|
        pager.replace traits
      end
      source_ids = Set.new(@traits.map { |trait| trait.source_id })
      source_ids.delete(nil) # Just in case.
      @sources = Resource.where(id: source_ids.to_a).includes(:content_partner)
    end
  end

  def get_pages(uris)
    ids = Set.new
    uris.each do |uri|
      if uri =~ TraitBank.taxon_re
        # NOTE: it stinks that we "know" that taxon_re puts the id in #2. :|
        ids << $2
      end
    end
    TaxonConcept.where(id: ids.to_a).with_titles
  end
end
