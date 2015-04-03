#encoding: utf-8
class TaxonData < TaxonUserClassificationFilter

  include EOL::Sparql::SafeConnection
  extend EOL::Sparql::SafeConnection
  MAXIMUM_DESCENDANTS_FOR_CLADE_RANGES = 15000

  def self.counts_of_values_from_search(options={})
    return { } if options[:attribute].blank?
    return { } unless EOL::Sparql.connection.counts_of_all_value_known_uris_by_type.keys.map(&:uri).include?(options[:attribute])
    counts_of_result_value_uris = EOL::Sparql.connection.query(
      EOL::Sparql::SearchQueryBuilder.prepare_search_query(options.merge({ count_value_uris: true, querystring: nil })))
    KnownUri.add_to_data(counts_of_result_value_uris)
    Hash[ counts_of_result_value_uris.collect{ |h| [ h[:value], h[:count] ] } ]
  end

  def self.is_clade_searchable?(taxon_concept)
    taxon_concept.number_of_descendants <= TripleStore::MAXIMUM_DESCENDANTS_FOR_CLADE_SEARCH
  end

  def downloadable?
    ! bad_connection? && ! get_data.blank?
  end

  def topics
    if @traits
      @topics ||=
        @traits.map { |t| t.try(:predicate_known_uri).try(:name) }.compact.uniq
    else
      if_connection_fails_return([]) do
         get_data.map { |d| d[:attribute] }.select { |a| a.is_a?(KnownUri) }.uniq.compact.map(&:name)
      end
    end
  end

  def categories
    if_connection_fails_return([]) do
      get_data unless @categories
      @categories
    end
  end

  def use_db?
    false # TODO!!!
  end

  # NOTE - nil implies bad connection. You should get a TaxonDataSet otherwise!
  def get_data
    # TODO: not sure why we're #dup'ing here, please explain:
    return @taxon_data_set.dup if defined?(@taxon_data_set)
    # TODO: For TRAMEA, we should check to see if we can use the DB, and if so:
    if use_db?
      return @traits = @taxon_concept.traits
    end
    if_connection_fails_return(nil) do
      taxon_data_set = TaxonDataSet.new(raw_data,
        taxon_concept: taxon_concept,
        language: user.language)
      taxon_data_set.sort
      # NOTE: I removed some includes here (known_uri_relationships) because I
      # didn't see them being used _anywhere_. TODO: I don't believe we SHOULD
      # be including translations. We only need one language. I'd rather select
      # them all later. I also don't think we should preload these here; we
      # still have a lot of URIs to gather... soooo... SKIP.
      known_uris = KnownUri.
        includes({ toc_items: :translations }).
        where(
          id: taxon_data_set.map { |d| d.predicate_known_uri_id }.compact.uniq
        )
      @categories = known_uris.flat_map(&:toc_items).compact.uniq
      @taxon_data_set = taxon_data_set
    end
    raise EOL::Exceptions::SparqlDataEmpty if @taxon_data_set.nil?
    @taxon_data_set
  end

  # TODO - spec for can see data check
  # NOTE - nil implies bad connection. Empty set ( [] ) implies nothing to show.
  def get_data_for_overview
    return nil unless user.can_see_data?
    picker = TaxonDataExemplarPicker.new(self).pick
  end

  def distinct_predicates
    data = get_data
    unless data.nil? || ranges_of_values.nil?
      ( data.collect{ |d| d.predicate }.compact +
        ranges_of_values.collect{ |r| r[:attribute] } ).uniq
    else
      return []
    end
  end

  def has_range_data
    ! ranges_of_values.empty?
  end

  def ranges_of_values
    return [] unless should_show_clade_range_data
    return @ranges_of_values if defined?(@ranges_of_values)
    EOL::Sparql::Client.if_connection_fails_return({}) do
      results = TripleStore.ranges(taxon_concept)
      # TODO: I don't think we need to load these right now.
      KnownUri.add_to_data(results)
      results.each do |result|
        [ :min, :max ].each do |m|
          result[m] = result[m].value.to_f if result[m].is_a?(RDF::Literal)
          result[m] =
            Trait.new(Trait.attributes_from_virtuoso_response(result).
              merge(object: result[m]))
          result[m].convert_units
        end
      end
      @ranges_of_values = show_preferred_unit(
        results.delete_if do |r|
          r[:min].object.blank? ||
          r[:max].object.blank? ||
          (r[:min].object == 0 && r[:max].object == 0)
        end
      )
    end
  end

  def show_preferred_unit(results)
    results.group_by { |r| r[:attribute] }.values.map do |attribute_group|
      attribute_group.sort do |a,b|
        if a[:unit_of_measure_uri] && b[:unit_of_measure_uri] &&
           a[:unit_of_measure_uri].is_a?(Hash) && b[:unit_of_measure_uri].is_a?(Hash)
          a[:unit_of_measure_uri][:position] <=> b[:unit_of_measure_uri][:position]
        else
          a[:unit_of_measure_uri] ? -1 : 1
        end
      end.first # Choose the value that sorted first.
    end
  end

  # TODO - spec for can see data check
  def ranges_for_overview
    return nil unless user.can_see_data?
    ranges_of_values.select{ |range| KnownUri.uris_for_clade_exemplars.include?(range[:attribute].uri) }
  end

  def jsonld
    Rails.cache.fetch("/taxa/#{taxon_concept.id}/data/json",
      expires_in: 24.hours) do
      to_jsonld
    end
  end

  # NO CACHE!
  def to_jsonld
    get_data.to_jsonld
  end

  def iucn_data_objects
    TripleStore.iucn_data_objects(taxon_concept)
  end

  def raw_data
    Rails.cache.fetch("/taxa/#{taxon_concept.id}/raw_data",
      expires_in: 12.hours) do
      (measurement_data + association_data).
        delete_if { |k,v| k[:attribute].blank? }
    end
  end

  # Find traits that are no longer in virtuoso and delete them. This takes a
  # second or two.
  # TODO: use this
  def delete_old_traits
    taxon_concept.traits.where([
      "traits.uri NOT in (?)", raw_data.map {|h| h[:data_point_uri].to_s }
    ]).delete_all
  end

  def measurement_data
    TripleStore.measurement_data(taxon_concept)
  end

  def association_data(options = {})
    TripleStore.association_data(taxon_concept)
  end
end
