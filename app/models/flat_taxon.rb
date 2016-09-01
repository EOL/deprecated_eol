class FlatEntry < ActiveRecord::Base
  belongs_to :hierarchy
  belongs_to :hierarchy_entry
  belongs_to :taxon_concept
  belongs_to :ancestor, class_name: "TaxonConcept", foreign_key: :ancestor_id

  scope :descendants_of, lambda { |ancestor_id| where('ancestor_id = ?', ancestor_id) }
  # NOTE: be careful with this one, it may not work with joins:
  scope :distinct, -> { selects("DISTINCT taxon_concept_id, ancestor_id") }

end
