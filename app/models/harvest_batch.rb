class HarvestBatch

  attr_reader :harvests, :start_time

  def add(resource)
    if @harvests.nil?
      @harvests = []
      @start_time = Time.now
    end
    @harvests << resource
  end

  def complete?
    Time.now > @start_time + 10.hours ||
      @harvests.count >= 5
  end

  def post_harvesting
    flatten_hierarchies_TODO # (see the PHP FlattenHierarchies library, as if passing in the hierarchy_ids!)
    pubish_pending_resources_TODO
    fix_published_flags_on_taxa_TODO
    TaxonConcept.trust_concepts_with_visible_trusted_entries(
      @harvests.map(&:hierarchy_id))
    # No nice way to do this on a set of hierarchies:
    TaxonConcept.untrust_concepts_with_no_visible_trusted_entries
    CollectionItem.remove_superceded_taxa
  end
end
