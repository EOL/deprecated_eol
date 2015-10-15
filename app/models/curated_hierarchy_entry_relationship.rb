# Used during harvesting (only).
class CuratedHierarchyEntryRelationship < ActiveRecord::Base
  self.primary_keys = "hierarchy_entry_id_1", "hierarchy_entry_id_2"

  belongs_to :from_hierarchy_entry, class_name: "HierarchyEntry",
    foreign_key: "hierarchy_entry_id_1"
  belongs_to :to_hierarchy_entry, class_name: "HierarchyEntry",
    foreign_key: "hierarchy_entry_id_2"

  scope :equivalent, -> { where(equivalent: true) }
end
