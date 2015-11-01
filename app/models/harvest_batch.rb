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
    ActiveRecord::Base.connection.with_master do
      @harvested_resources.each do |resource|
        resource.hierarchy.flatten
        resource.publish
      end
      denormalize_tables
    rescue => e
      EOL.log("ERROR: #{e.message}", prefix: "!")
      # TODO: there are myriad errors that harvesting can throw; catch them here.
    end
  end

  def denormalize_tables
    EOL.log_call
    DataObjectsTaxonConceptsDenormalizer.denormalize
    # TODO: this is really silly. We should just handle this as we do the
    # harvest... no need to rebuild the WHOLE THING every time! Just silly.
    # Bah. ...Can't add that until we port harvesting, though.
    DataObjectsTableOfContent.rebuild
    # TODO: this is not an efficient algorithm. We should change this to store
    # the scores in the DB as well as some kind of tree-structure of taxa
    # (which could also be used elsewhere!), and then build things that way;
    # we should also actually store the sort order in this table, rather than
    # overloading the id (!); that would allow us to update the table only as
    # needed, based on what got harvested (i.e.: a list of data objects
    # inserted could be used to figure out where they lie in the sort, and
    # update the orders as needed based on that—much faster.)
    TopImage.rebuild
    RandomHierarchyImage.create_random_images_from_rich_taxa
    TaxonConceptPreferredEntry.rebuild
    CollectionItem.remove_superceded_taxa
    EOL.log("denormalize_tables finished", prefix: "#")
  end

  def time_out?
    Time.now > @start_time + 10.hours
  end
end
