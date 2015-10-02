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
    fix_improperly_trusted_concepts_TODO
    remove_superceded_collection_items_TODO
  end
end
