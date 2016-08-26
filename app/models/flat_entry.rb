class FlatEntry < ActiveRecord::Base
  belongs_to :hierarchy_entry
  belongs_to :ancestor, class_name: HierarchyEntry.to_s, foreign_key: :ancestor_id
end
