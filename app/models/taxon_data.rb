#encoding: utf-8
class TaxonData < TaxonUserClassificationFilter

  include EOL::Sparql::SafeConnection
  extend EOL::Sparql::SafeConnection
  DEFAULT_PAGE_SIZE = 30
  MAXIMUM_DESCENDANTS_FOR_CLADE_RANGES = 15000
  MAXIMUM_DESCENDANTS_FOR_CLADE_SEARCH = 60000

  # TODO - this doesn't belong here; it has nothing to do with a taxon concept.
  # Move to a DataSearch class. Fix the controller.
  def self.search(options={})
    if_connection_fails_return(nil) do
      # only attribute is required, querystring may be left blank to get all usages of an attribute
      return [].paginate if options[:attribute].blank? # TODO - remove this when we allow other searches!
      options[:page] ||= 1
      options[:per_page] ||= TaxonData::DEFAULT_PAGE_SIZE
      options[:language] ||= Language.default
      total_results = EOL::Sparql.connection.query(EOL::Sparql::SearchQueryBuilder.prepare_search_query(options.merge(only_count: true))).first[:count].to_i
      results = EOL::Sparql.connection.query(EOL::Sparql::SearchQueryBuilder.prepare_search_query(options))
      # TODO - we should probably check for taxon supercedure, here.
      if options[:for_download]
        # when downloading, we don't the full TaxonDataSet which will want to insert rows into MySQL
        # for each DataPointUri, which is very expensive when downloading lots of rows
        KnownUri.add_to_data(results)
        data_point_uris = results.collect do |row|
          data_point_uri = DataPointUri.new(DataPointUri.attributes_from_virtuoso_response(row))
          data_point_uri.convert_units
          data_point_uri
        end
        DataPointUri.preload_associations(data_point_uris, { taxon_concept:
            [ { preferred_entry: { hierarchy_entry: { name: :ranked_canonical_form } } } ],
            resource: :content_partner },
          select: {
            taxon_concepts: [ :id, :supercedure_id ],
            hierarchy_entries: [ :id, :taxon_concept_id, :name_id ],
            names: [ :id, :string, :ranked_canonical_form_id ],
            canonical_forms: [ :id, :string ] }
          )
      else
        taxon_data_set = TaxonDataSet.new(results)
        data_point_uris = taxon_data_set.data_point_uris
        DataPointUri.preload_associations(data_point_uris, :taxon_concept)
        # This next line is for catching a rare case, seen in development, when the concept
        # referred to by Virtuoso is not in the database
        data_point_uris.delete_if{ |dp| dp.taxon_concept.nil? }
        TaxonConcept.preload_for_shared_summary(data_point_uris.collect(&:taxon_concept), language_id: options[:language].id)
      end
      TaxonConcept.load_common_names_in_bulk(data_point_uris.collect(&:taxon_concept), options[:language].id)
      WillPaginate::Collection.create(options[:page], options[:per_page], total_results) do |pager|
         pager.replace(data_point_uris)
      end
    end
  end

  def self.counts_of_values_from_search(options={})
    return { } if options[:attribute].blank?
    return { } unless EOL::Sparql.connection.counts_of_all_value_known_uris_by_type.keys.map(&:uri).include?(options[:attribute])
    counts_of_result_value_uris = EOL::Sparql.connection.query(
      EOL::Sparql::SearchQueryBuilder.prepare_search_query(options.merge({ count_value_uris: true, querystring: nil })))
    KnownUri.add_to_data(counts_of_result_value_uris)
    Hash[ counts_of_result_value_uris.collect{ |h| [ h[:value], h[:count] ] } ]
  end

  def self.is_clade_searchable?(taxon_concept)
    taxon_concept.number_of_descendants <= TaxonData::MAXIMUM_DESCENDANTS_FOR_CLADE_SEARCH
  end

  def downloadable?
    ! bad_connection? && ! get_data.blank?
  end

  def topics
    if_connection_fails_return([]) do
      @topics ||= get_data.map { |d| d[:attribute] }.select { |a| a.is_a?(KnownUri) }.uniq.compact.map(&:name)
    end
  end

  def categories
    if_connection_fails_return([]) do
      get_data unless @categories
      @categories
    end
  end

  # NOTE - nil implies bad connection. You should get a TaxonDataSet otherwise!
  def get_data
    return @taxon_data_set.dup if defined?(@taxon_data_set)
    if_connection_fails_return(nil) do
      taxon_data_set = TaxonDataSet.new(raw_data,
        taxon_concept: taxon_concept,
        language: user.language)
      taxon_data_set.sort
      # NOTE: I removed some includes here (known_uri_relationships) because I
      # didn't see them being used _anywhere_.
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
      results = SparqlQuery.ranges(taxon_concept).
        delete_if { |r| r[:measurementOfTaxon] != Rails.configuration.uri_true }
        KnownUri.add_to_data(results)
        results.each do |result|
          [ :min, :max ].each do |m|
            result[m] = result[m].value.to_f if result[m].is_a?(RDF::Literal)
            result[m] = DataPointUri.new(DataPointUri.attributes_from_virtuoso_response(result).merge(object: result[m]))
            result[m].convert_units
        end
      end
      @ranges_of_values = show_preferred_unit(results.delete_if{ |r| r[:min].object.blank? || r[:max].object.blank? || (r[:min].object == 0 && r[:max].object == 0) })
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

  # we only need a set number of attributes for GGI, and we know there are no
  # associations so it is more efficient to have a custom query to gather these
  # data. We might be able to generalize this, for example if we return search
  # results for multiple attributes
  def data_for_ggi
    results = SparqlQuery.ggi(taxon_concept)
    KnownUri.add_to_data(results)
    Resource.add_to_data(results)
    results
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
    SparqlQuery.iucn_data_objects(taxon_concept)
  end

  private

  def raw_data
    Rails.cache.fetch("/taxa/#{taxon_concept.id}/raw_data",
      expires_in: 12.hours) do
      (measurement_data + association_data).
        delete_if { |k,v| k[:attribute].blank? }
    end
  end

  def measurement_data
    SparqlQuery.measurements(taxon_concept)
  end

  def association_data
    SparqlQuery.associations(taxon_concept)
  end
end
