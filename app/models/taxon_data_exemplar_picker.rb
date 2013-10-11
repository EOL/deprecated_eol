class TaxonDataExemplarPicker

  @max_rows = SiteConfigurationOption.max_taxon_data_exemplars rescue 8

  def self.max_rows
    @max_rows
  end

  def initialize(taxon_data)
    @taxon_data = taxon_data
    @taxon_concept_id = taxon_data.taxon_concept.id
  end

  def pick(taxon_data_set)
    # TODO - Might be wise here to grab exemplars first; if there are enough to fill the list, no need to load all the data.
    taxon_data_set = reject_bad_known_uris(taxon_data_set)
    taxon_data_set = reject_hidden(taxon_data_set)
    taxon_data_set = reject_exemplars(taxon_data_set)
    pick_exemplars(taxon_data_set.uniq.sort)
  end

  # For posterity, here were the four that used to be hard-coded here:
  #   'http://iobis.org/maxaou',
  #   'http://iobis.org/minaou',
  #   'http://iobis.org/maxdate',
  #   'http://iobis.org/mindate'
  def reject_bad_known_uris(taxon_data_set)
    uris_to_reject = KnownUri.excluded_from_exemplars.select('uri').map(&:uri)
    taxon_data_set.delete_if do |data_point_uri|
      if data_point_uri.predicate_known_uri
        uris_to_reject.detect{ |uri| data_point_uri.predicate_known_uri.matches(uri) }
      else
        uris_to_reject.include?(data_point_uri.predicate)
      end
    end
    taxon_data_set
  end

  def reject_exemplars(taxon_data_set)
    # TODO - (Possibly) cache this.
    exemplars_to_reject = TaxonDataExemplar.where(taxon_concept_id: @taxon_concept_id).excluded
    taxon_data_set.delete_if do |data_point_uri|
      exemplars_to_reject.any? { |ex| data_point_uri.id == ex.data_point_uri.id }
    end
    taxon_data_set
  end

  def reject_hidden(taxon_data_set)
    taxon_data_set.delete_if do |data_point_uri|
      data_point_uri.hidden?
    end
    taxon_data_set
  end

  def pick_exemplars(taxon_data_set)
    return taxon_data_set if taxon_data_set.count <= TaxonDataExemplarPicker.max_rows # No need to load anything, otherise...
    # TODO - this should have an #include in it, but I'm being lazy:
    curated_exemplars = TaxonDataExemplar.where(taxon_concept_id: @taxon_concept_id).map(&:data_point_uri).delete_if {|p| p.hidden? }
    # NOTE the following clause assumes that exemplars will be deleted when rows are deleted:
    if curated_exemplars.count >= TaxonDataExemplarPicker.max_rows
      return taxon_data_set.select { |data_point_uri| curated_exemplars.include?(data_point_uri) }
    end
    # If we're still here, we have too many.
    while(taxon_data_set.count > TaxonDataExemplarPicker.max_rows) do
      taxon_data_set.delete_at(index_of_last_non_exemplar(taxon_data_set, curated_exemplars))
    end
    taxon_data_set
  end

  def index_of_last_non_exemplar(taxon_data_set, curated_exemplars)
    (TaxonDataExemplarPicker.max_rows-1).downto(0).each do |i|
      next if curated_exemplars.include?(taxon_data_set[i])
      return i
    end
  end

end
