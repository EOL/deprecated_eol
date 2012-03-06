class HierarchyEntriesRef < ActiveRecord::Base
  
  belongs_to :hierarchy_entry
  belongs_to :ref
  
end