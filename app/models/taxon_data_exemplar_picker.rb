class TaxonDataExemplarPicker

  @max_rows = EolConfig.max_taxon_data_exemplars rescue 8
  @max_values_per_row = EolConfig.max_taxon_data_exemplar_values_per_row rescue 3

  def self.max_rows
    @max_rows
  end

  def self.max_values_per_row
    @max_values_per_row
  end

  def self.group_and_sort_data_points(data_point_uris)
    data_point_uris.delete_if{ |dp| dp.predicate_uri.blank? }
    grouped_points = data_point_uris.uniq.sort.group_by(&:grouping_factors)
    # Creating a hash which contains the above groups, indexed by some representative
    # of the group that we can use for display purposes
    # { representative => [ data_point_uris: ..., show_more: true/false ] }
    final_hash = {}
    grouped_points.each do |grouped_by, data_point_uris|
      representative = data_point_uris.first
      final_hash[representative] = {}
      final_hash[representative][:data_point_uris] = data_point_uris[0...TaxonDataExemplarPicker::max_values_per_row]
      if data_point_uris.length > TaxonDataExemplarPicker::max_values_per_row
        final_hash[representative][:show_more] = true
      end
    end
    final_hash
  end

  def self.count_rows_in_set(data_set)
    data_set.collect(&:grouping_factors).uniq.length
  end

  def initialize(taxon_data)
    @taxon_data = taxon_data
    @taxon_concept_id = taxon_data.taxon_concept.id
  end

  # Note - returns nil if the connection to the triplestore is bad.
  def pick
    return nil if @taxon_data.get_data.nil? # The server is down.
    @taxon_data_set = @taxon_data.get_data.clone
    return nil unless @taxon_data_set # This occurs if the connection to the triplestore is broken or bad.
    @exemplar_data_points = exemplar_data_points
    reject_excluded_known_uris
    reject_hidden_data_point_uris
    reject_excluded_data_point_uris
    reduce_size_of_results
    TaxonDataExemplarPicker.group_and_sort_data_points(@taxon_data_set)
  end

  # For posterity, here were the four that used to be hard-coded here:
  #   'http://iobis.org/maxaou',
  #   'http://iobis.org/minaou',
  #   'http://iobis.org/maxdate',
  #   'http://iobis.org/mindate'
  def reject_excluded_known_uris
    uris_to_reject = KnownUri.excluded_from_exemplars.select('uri').map(&:uri)
    @taxon_data_set.delete_if do |data_point_uri|
      if data_point_uri.predicate_known_uri
        uris_to_reject.detect{ |uri| data_point_uri.predicate_known_uri.matches(uri) }
      else
        uris_to_reject.include?(data_point_uri.predicate)
      end
    end
  end

  def reject_excluded_data_point_uris
    # TODO - (Possibly) cache this.
    exemplars_to_reject = TaxonDataExemplar.where(taxon_concept_id: @taxon_concept_id).excluded
    @taxon_data_set.delete_if do |data_point_uri|
      exemplars_to_reject.any? { |ex| data_point_uri.id == ex.data_point_uri.id }
    end
  end

  def reject_hidden_data_point_uris
    @taxon_data_set.delete_if do |data_point_uri|
      data_point_uri.hidden?
    end
  end

  def reduce_size_of_results
    reduced_set, more_points = @taxon_data_set.partition{ |point| @exemplar_data_points.include?(point) }
    more_points.sort!
    while TaxonDataExemplarPicker.count_rows_in_set(reduced_set) < TaxonDataExemplarPicker.max_rows && ! more_points.empty?
      reduced_set << more_points.shift
    end
    @taxon_data_set = reduced_set
  end

  def exemplar_data_points
    TaxonDataExemplar.included.
      where(taxon_concept_id: @taxon_concept_id).
      map(&:data_point_uri).compact.delete_if {|p| p.hidden? }
  end

end
