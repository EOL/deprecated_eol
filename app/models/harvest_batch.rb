class HarvestBatch
  attr_reader :resources, :start_time

  def initialize(ids = [])
    EOL.log_call
    @start_time = Time.now
    @resource_ids = Array(ids)
    @summary = []
    EOL.log("Resources: #{@resource_ids.join(", ")}", prefix: ".") unless
      @resource_ids.empty?
  end

  def add(id)
    @resource_ids << id
  end

  def complete?
    EOL.log_call
    if batch.maximum_count?
      EOL.log("count (#{count}) exceeds maximum count", prefix: '.')
      return true
    elsif batch.time_out?
      EOL.log("timed out, started at #{start_time}", prefix: '.')
      return true
    end
    false
  end

  def count
    @resource_ids.count
  end

  def maximum_count?
    count >= EolConfig.max_harvest_batch_count.to_i rescue 5
  end

  def post_harvesting
    EOL.log_call
    ActiveRecord::Base.with_master do
      any_worked = false
      resources = Resource.where(id: @resource_ids).
        includes([:resource_status, :hierarchy])
      resources.each do |resource|
        url = "http://eol.org/content_partners/"\
          "#{resource.content_partner_id}/resources/#{resource.id}"
        @summary << { title: resource.title, url: url }
        EOL.log("POST-HARVEST: #{resource.title}", prefix: "H")
        unless resource.ready_to_publish?
          status = resource.resource_status.label
          EOL.log("SKIPPING (status #{status}): "\
            "#{resource.id} - Must be 'Processed' to publish")
          @summary.last[:status] = "Skipped (#{status})"
          next
        end
        begin
          resource.hierarchy.flatten
          # TODO - somewhere in the UI we can trigger a publish on a resource.
          # Make it run #publish (in the background) NOTE: this used to check
          # for preview vs. publish, but we don't want to preview ever, anymore.
          resource.publish
          EOL.log("POST-HARVEST COMPLETE: #{resource.title} (#{resource.id})",
            prefix: "H")
          any_worked = true
          @summary.last[:status] = "completed"
        # TODO: there are myriad specific errors that harvesting can throw; catch
        # them here.
        rescue => e
          EOL.log("POST-HARVEST FAILED: #{resource.title}", prefix: "H")
          EOL.log_error(e)
          @summary.last[:status] = "FAILED"
        end
      end
      if any_worked
        if CodeBridge.top_images_in_queue?
          EOL.log("'top_images' already enqueued in 'php'; skipping",
            prefix: ".")
        else
          EOL.log("SKIPPING TOP IMAGES! (takes too long)", prefix: "!")
          denormalize_tables
          # EOL.log("Enqueue 'top_images' in 'php'", prefix: ".")
          # Resque.enqueue(CodeBridge, {'cmd' => 'top_images'})
        end
      else
        EOL.log("Nothing was published; skipping denormalization", prefix: "!")
      end
      EOL.log("PUBLISHING SUMMARY:", prefix: "<")
      @summary.each do |stat|
        EOL.log("[#{stat[:title]}](#{stat[:url]}) #{stat[:status]}")
      end
    end
    EOL.log_return
  end

  # TODO: this does not belong here. Move it.
  def denormalize_tables
    EOL.log_call
    last_time = EolConfig.last_denormalize
    # TODO: in an *ideal* world, this would only run once a day (suggest 7:00
    # AM), at a prescribed time, and only if something had changed since the
    # last run... so really we would have a cron task handle this if
    # EolConfig.denormalize_needed was true... and here we would set that to
    # true.
    if Time.parse(last_time) < 1.day.ago
      EOL.log("Tables were already denormalized on #{last_time}; skipping.")
      return
    end
    # TODO: this is not an efficient algorithm. We should change this to store
    # the scores in the DB as well as some kind of tree-structure of taxa
    # (which could also be used elsewhere!), and then build things that way;
    # we should also actually store the sort order in this table, rather than
    # overloading the id (!); that would allow us to update the table only as
    # needed, based on what got harvested (i.e.: a list of data objects
    # inserted could be used to figure out where they lie in the sort, and
    # update the orders as needed based on that—much faster.)
    RandomHierarchyImage.create_random_images_from_rich_taxa
    TaxonConceptPreferredEntry.rebuild
    EolConfig.create(parameter: "last_denormalize", value: Time.now)
    EOL.log_return
  end

  def time_out?
    Time.now > @start_time + 10.hours
  end
end
