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
    EOL.log_call
    EOL.log("Y: maximum count", prefix: '.') if batch.maximum_count?
    EOL.log("Y: timed out, started at #{start_time}", prefix: '.') if
      batch.time_out?
    time_out? || maximum_count?
  end

  def count
    @harvested_resources.count
  end

  def maximum_count?
    count >= EolConfig.max_harvest_batch_count.to_i rescue 5
  end

  def post_harvesting
    ActiveRecord::Base.with_master do
      begin
        @harvested_resources.each do |resource|
          resource.hierarchy.flatten
          # TODO (IMPORTANT) - somewhere in the UI we can trigger a publish on a
          # resource. Make it run #publish (in the background)! YOU WERE HERE
          if resource.auto_publish?
            resource.publish
          else
            resource.preview
          end
        end
        #WAIT: needs to be called async'ly: denormalize_tables
      # TODO: there are myriad specific errors that harvesting can throw; catch
      # them here.
      rescue => e
        EOL.log_error(e)
      end
    end
  end

  def denormalize_tables
    EOL.log_call
    # TODO: this is not an efficient algorithm. We should change this to store
    # the scores in the DB as well as some kind of tree-structure of taxa
    # (which could also be used elsewhere!), and then build things that way;
    # we should also actually store the sort order in this table, rather than
    # overloading the id (!); that would allow us to update the table only as
    # needed, based on what got harvested (i.e.: a list of data objects
    # inserted could be used to figure out where they lie in the sort, and
    # update the orders as needed based on that—much faster.)
    # WAIT: don't trust this; do it from harvest: TopImage.rebuild
    RandomHierarchyImage.create_random_images_from_rich_taxa
    TaxonConceptPreferredEntry.rebuild
    CollectionItem.remove_superceded_taxa
    EOL.log_return
  end

  def time_out?
    Time.now > @start_time + 10.hours
  end
end
