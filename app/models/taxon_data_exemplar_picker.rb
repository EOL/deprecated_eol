class TaxonDataExemplarPicker

  MAX_ROWS = 5 # TODO - pick a number, move this to the DB or something.

  def initialize(taxon_data)
    @taxon_data = taxon_data
    @taxon_concept_id = taxon_data.taxon_concept.id
  end

  def pick(rows)
    # TODO - Might be wise here to grab exemplars first; if there are enough to fill the list, no need to load all the data.
    rows = reject_bad_known_uris(rows)
    rows.add_parents # Expensive, but (ATM) we need to know what the parents are.
    rows = reject_hidden(rows)
    rows = reject_exemplars(rows)
    pick_exemplars(rows.sort.uniq)
  end

  # For posterity, here were the four that used to be hard-coded here:
  #   'http://iobis.org/maxaou',
  #   'http://iobis.org/minaou',
  #   'http://iobis.org/maxdate',
  #   'http://iobis.org/mindate'
  def reject_bad_known_uris(rows)
    uris_to_reject = KnownUri.excluded_from_exemplars.select('uri').map(&:uri)
    rows.delete_if do |r|
      if r[:attribute].is_a?(KnownUri)
        uris_to_reject.detect{ |uri| r[:attribute].matches(uri) }
      else
        uris_to_reject.include?(r[:attribute].to_s)
      end
    end
    rows
  end

  def reject_exemplars(rows)
    # TODO - (Possibly) cache this.
    exemplars_to_reject = TaxonDataExemplar.where(taxon_concept_id: @taxon_concept_id).excluded
    rows.delete_if do |row|
      exemplars_to_reject.any? { |ex| row[:parent].class.name == ex.parent_type && row[:parent].id == ex.parent_id }
    end
    rows
  end

  def reject_hidden(rows)
    rows.delete_if do |row|
      row[:parent].hidden?
    end
    rows
  end

  def pick_exemplars(rows)
    return rows if rows.count <= MAX_ROWS # No need to load anything, otherise...
    # TODO - this should have an #include in it, but I'm being lazy:
    curated_exemplars = TaxonDataExemplar.where(taxon_concept_id: @taxon_concept_id).map(&:parent).delete_if {|p| p.hidden? }
    # NOTE the following clause assumes that exemplars will be deleted when rows are deleted:
    return rows.select { |r| curated_exemplars.include?(r[:parent]) } if curated_exemplars.count >= MAX_ROWS
    # If we're still here, we have too many.
    while(rows.count > MAX_ROWS) do
      rows.delete_at(index_of_last_non_exemplar(rows, curated_exemplars))
    end
    rows
  end

  def index_of_last_non_exemplar(rows, curated_exemplars)
    (MAX_ROWS-1).downto(0).each do |i|
      next if curated_exemplars.include?(rows[i][:parent])
      return i
    end
  end

end
