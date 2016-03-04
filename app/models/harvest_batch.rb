class HarvestBatch

  attr_reader :resources, :start_time

  def initialize(resources = [])
    EOL.log_call
    @start_time = Time.now
    @resources = Array(resources)
    EOL.log("Resources: #{@resources.map(&:id)}", prefix: ".") unless
      @resources.empty?
  end

  def add(resource)
    @resources << resource
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
    @resources.count
  end

  def maximum_count?
    count >= EolConfig.max_harvest_batch_count.to_i rescue 5
  end

  def post_harvesting
    EOL.log_call
    ActiveRecord::Base.with_master do
      any_worked = false
      @resources.each do |resource|
        url = "http://eol.org/content_partners/"\
          "#{resource.content_partner_id}/resources/#{resource.id}"
        EOL.log("POST-HARVEST: #{resource.title}", prefix: "H")
        EOL.log(url)
        unless resource.ready_to_publish?
          EOL.log("SKIPPING (status #{resource.resource_status.label}): "\
            "#{resource.id} - Must be 'Processed' to publish")
          next
        end
        begin
          resource.hierarchy.flatten
          # TODO (IMPORTANT) - somewhere in the UI we can trigger a publish on a
          # resource. Make it run #publish (in the background)! YOU WERE HERE
          if resource.auto_publish?
            resource.publish
          else
            resource.preview
          end
          EOL.log("POST-HARVEST: #{resource.title} COMPLETE", prefix: "H")
          EOL.log(url)
          any_worked = true
        # TODO: there are myriad specific errors that harvesting can throw; catch
        # them here.
        rescue => e
          EOL.log("POST-HARVEST FAILED:", prefix: "H")
          EOL.log_error(e)
        end
      end
      if any_worked
        if CodeBridge.top_images_in_queue?
          EOL.log("'top_images' already enqueued in 'php'; skipping",
            prefix: ".")
        else
          EOL.log("Enqueue 'top_images' in 'php'", prefix: ".")
          Resque.enqueue(CodeBridge, {'cmd' => 'top_images'})
        end
      else
        EOL.log("Nothing was published; skipping denormalization", prefix: "!")
      end
    end
    EOL.log_return
  end

  # TODO: this does not belong here. Move it.
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
    RandomHierarchyImage.create_random_images_from_rich_taxa
    TaxonConceptPreferredEntry.rebuild
    CollectionItem.remove_superceded_taxa
    EOL.log_return
  end

  def time_out?
    Time.now > @start_time + 10.hours
  end
end
