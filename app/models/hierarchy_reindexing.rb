class HierarchyReindexing < ActiveRecord::Base

  belongs_to :hierarchy
  scope :pending, -> { where( completed_at: nil ) }
  @queue = 'notifications'

  def self.enqueue(which)
      @self = HierarchyReindexing.create( hierarchy_id: which.id )
      Resque.enqueue(HierarchyReindexing, id: @self.id)
  end

  def self.perform(args)
    Rails.logger.error("HierarchyReindexing: #{args.values.join(', ')}")
    if HierarchyReindexing.exists?(args["id"])
        begin
          HierarchyReindexing.find(args["id"]).run
        rescue => e
          Rails.logger.error "HierarchyReindexing (#{args["id"]}) FAILED: "\
            " #{e.message}"
        end
    else
       Rails.logger.error "HierarchyReindexing #{args["id"]} doesn't exist, skippped."
    end
  end

  def run
    start
    hierarchy.repopulate_flattened
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
