# TODO: this class is NOT NEEDED. Refactor and remove; simply process by
# hierarchy id.
class HierarchyReindexing < ActiveRecord::Base

  belongs_to :hierarchy
  scope :pending, -> { where( completed_at: nil ) }
  # Putting this in the harvesting queue because if one of these is running, it
  # runs the risk of screwing up a harvest (by locking a table and causing a
  # timeout)
  @queue = 'harvesting'

  class << self
    def enqueue_unless_pending(which, options = {})
      queue = HierarchyReindexing.instance_eval { @queue } || :harvesting
      HierarchyReindexing.with_master do
        return false if Resque.size(queue) > 100 # The queue is overwhelmed, wait.
        pending = Background.in_queue?(queue, HierarchyReindexing,
          "hierarchy_id", which.id)
        return false if pending
      end
      HierarchyReindexing.enqueue(which, options)
      true
    end

    def enqueue(which, options = {})
      HierarchyReindexing.with_master do
        HierarchyReindexing.where(hierarchy_id: which.id).delete_all
      end
      @self = HierarchyReindexing.create(hierarchy_id: which.id)
      Resque.enqueue(HierarchyReindexing, options.merge(id: @self.id, hierarchy_id: which.id))
    end

    def perform(args)
      HierarchyReindexing.with_master do
        if HierarchyReindexing.exists?(args["id"])
          begin
            EOL.log("HierarchyReindexing: #{args}", prefix: "R")
            HierarchyReindexing.find(args["id"]).run(args["from"])
          rescue => e
            EOL.log("HierarchyReindexing #{args["id"]} FAILED: #{e.message}",
              prefix: "!")
          end
        else
          # Do nothing for now—for some reason this is happening a LOT, so let's
          # just silently ignore it
        end
      end
    end
  end

  def run(from = nil)
    start
    if from
      entry = HierarchyEntry.find(from)
      ancestors = entry.flat_ancestors
      if ancestors.empty? and entry.parent_id > 0
        hierarchy.flatten
      else
        EOL.log("SKIPPING: this ancestry appears to be fine!")
        EOL.log("  http://eol.org/pages/#{entry.taxon_concept_id} parent_id: #{entry.parent_id}, ancestors: #{ancestors.join(",")})")
      end
    else
      hierarchy.flatten
    end
    complete
  end

  def start
    update_attributes(started_at: Time.now)
    update_attributes(completed_at: nil)
  end

  def complete
    update_attributes(completed_at: Time.now)
  end
end
