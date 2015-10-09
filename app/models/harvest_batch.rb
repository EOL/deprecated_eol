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
    # YOU WERE HERE (you're working on a submethod of publish_pending ATM (in
    # resource/publisher.rb), but also need to do the next line, obviously:)
    flatten_hierarchies_TODO # (see the PHP FlattenHierarchies library, as if passing in the hierarchy_ids!)
    begin
      Resource.publish_pending
    rescue => e
      EOL.log("ERROR: #{e.message}", prefix: "!")
      # TODO: there are myriad errors that harvesting can throw; catch them here.
    end
    CollectionItem.remove_superceded_taxa
  end
end
