class HarvestEventsHierarchyEntry < ActiveRecord::Base
  belongs_to :harvest_event
  belongs_to :hierarchy_entry
  belongs_to :status
end
