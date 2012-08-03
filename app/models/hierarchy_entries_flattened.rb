class HierarchyEntriesFlattened < ActiveRecord::Base
  self.table_name = "hierarchy_entries_flattened"
  belongs_to :hierarchy_entries
  belongs_to :ancestor, :class_name => HierarchyEntry.to_s, :foreign_key => :ancestor_id
end
