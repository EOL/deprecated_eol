class TaxonConceptsFlattened < ActiveRecord::Base

  self.table_name = "taxon_concepts_flattened"
  self.primary_keys = [:taxon_concept_id, :ancestor_id]

  belongs_to :taxon_concepts

  scope :descendants_of, lambda {|ancestor_id| where('ancestor_id = ?', ancestor_id) }

end
