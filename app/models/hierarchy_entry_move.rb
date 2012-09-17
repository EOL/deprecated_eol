class HierarchyEntryMove < ActiveRecord::Base

  named_scope :with_errors, :conditions => ["error IS NOT NULL AND error != ''"]

  belongs_to :classification_curation
  belongs_to :hierarchy_entry

  # The only other values on this model are :completed_at and :error ...otherwise this is a standard join model.
  # Note that completed_at is set EVEN WHEN THERE WAS AN ERROR.

end
