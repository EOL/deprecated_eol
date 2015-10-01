class HarvestBatch

  attribute_accessor :harvests, :start_time

  def add(resource)
    @harvests ||= []
    @harvests << resource
  end

  def complete?
    Time.now > @start_time + 10.hours ||
      @harvests.count >= 5
  end

  def post_harvesting
    pubish_pending_resources_TODO
    fix_published_flags_on_taxa_TODO
    fix_improperly_trusted_concepts_TODO
    remove_superceded_collection_items_TODO
  end
end
