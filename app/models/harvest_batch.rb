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
    Resource.publish_pending
    CollectionItem.remove_superceded_taxa
  end
end
