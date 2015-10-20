class HarvestBatch

  attr_reader :harvested_resources, :start_time

  def add(resource)
    if @harvested_resources.nil?
      @harvested_resources = []
      @start_time = Time.now
    end
    @harvested_resources << resource
  end

  def complete?
    time_out? || maximum_count?
  end

  def count
    @harvested_resources.count
  end

  def maximum_count?
    count >= EolConfig.max_harvest_batch_count.to_i rescue 5
  end

  def post_harvesting
    begin
      @harvested_resources.each do |resource|
        resource.hierarchy.flatten
        resource.publish
      end
    rescue => e
      EOL.log("ERROR: #{e.message}", prefix: "!")
      # TODO: there are myriad errors that harvesting can throw; catch them here.
    end
    CollectionItem.remove_superceded_taxa
  end

  def time_out?
    Time.now > @start_time + 10.hours
  end
end
