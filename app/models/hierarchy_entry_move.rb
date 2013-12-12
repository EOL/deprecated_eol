class HierarchyEntryMove < ActiveRecord::Base

  scope :with_errors, conditions: ["error IS NOT NULL AND error != ''"]
  scope :pending, conditions: ["completed_at IS NULL"]

  belongs_to :classification_curation
  belongs_to :hierarchy_entry

  # The only other values on this model are :completed_at and :error ...otherwise this is a standard join model.
  # Note that completed_at is set EVEN WHEN THERE WAS AN ERROR.

  def complete?
    completed_at?
  end

end
