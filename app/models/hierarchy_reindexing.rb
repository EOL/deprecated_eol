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
    def enqueue_unless_pending(which)
      HierarchyReindexing.with_master do
        pending = Background.in_queue?(:notifications, HierarchyReindexing,
          "hierarchy_id", which.id)
        return false if pending
      end
      HierarchyReindexing.enqueue(which)
      true
    end

    def enqueue(which)
      HierarchyReindexing.with_master do
        HierarchyReindexing.where(hierarchy_id: which.id).delete_all
      end
      @self = HierarchyReindexing.create(hierarchy_id: which.id)
      Resque.enqueue(HierarchyReindexing, id: @self.id, hierarchy_id: which.id)
    end

    def perform(args)
      HierarchyReindexing.with_master do
        if HierarchyReindexing.exists?(args["id"])
            begin
              Rails.logger.error("HierarchyReindexing: #{args.values.join(', ')}")
              HierarchyReindexing.find(args["id"]).run
            rescue => e
              Rails.logger.error "HierarchyReindexing (#{args["id"]}) FAILED: "\
                " #{e.message}"
            end
        else
          # Do nothing for now—for some reason this is happening a LOT, so let's
          # just silently ignore it:
          # Rails.logger.error("HierarchyReindexing #{args["id"]} "\
          #   "doesn't exist, skippped.")
        end
      end
    end
  end

  def run
    start
    hierarchy.flatten
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
