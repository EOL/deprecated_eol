class TaxonConceptsFlattened < ActiveRecord::Base

  self.table_name = "taxon_concepts_flattened"

  belongs_to :taxon_concepts

  scope :descendants_of, lambda {|ancestor_id| where('ancestor_id = ?', ancestor_id) }

end
