class TaxonDataExemplarPicker

  @max_rows = SiteConfigurationOption.max_taxon_data_exemplars rescue 8

  def self.max_rows
    @max_rows
  end

  def initialize(taxon_data)
    @taxon_data = taxon_data
    @taxon_concept_id = taxon_data.taxon_concept.id
  end

  # Note - returns nil if the connection to the triplestore is bad.
  # TODO - why are we taking an argument, here? We HAVE the TaxonData, and thus the data set.
  def pick(taxon_data_set)
    return nil unless taxon_data_set # This occurs if the connection to the triplestore is broken or bad.
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

  # TODO - this should really return the categorized set.
  # TODO - this should also account for all the values in the categorized set... we only want some from each category.
  # TODO - this seems to be modifying the actual set of data on the source TaxonData object. Stop that.
  def pick_exemplars(taxon_data_set)
    return taxon_data_set if taxon_data_set.categorized.keys.count <= TaxonDataExemplarPicker.max_rows # No need to load anything, otherise...
    # TODO - this should have an #include in it, but I'm being lazy:
    curated_exemplars = TaxonDataExemplar.included.where(taxon_concept_id: @taxon_concept_id).map(&:data_point_uri).delete_if {|p| p.hidden? }
    # Curators have selected so many "good" rows, we're just going to show them all. NOTE this can exeed the limit! (but, at
    # the time of this writing, there is another check in the view that stops it from showing them all.).
    if curated_exemplars.count >= TaxonDataExemplarPicker.max_rows
      return taxon_data_set.delete_if { |data_point_uri| ! curated_exemplars.include?(data_point_uri) }
    end
    # If we're still here (and this is common), we have too many, can curators haven't selected enough to fill the allowed slots:
    while(taxon_data_set.categorized.keys.count > TaxonDataExemplarPicker.max_rows) do
      taxon_data_set.delete_at(index_of_last_non_exemplar(taxon_data_set, curated_exemplars))
    end
    taxon_data_set
  end

  def index_of_last_non_exemplar(taxon_data_set, curated_exemplars)
    (taxon_data_set.count - 1).downto(0).each do |i|
      next if curated_exemplars.include?(taxon_data_set[i])
      return i
    end
  end

end
