class TaxonConceptsFlattened < ActiveRecord::Base
  self.table_name = "taxon_concepts_flattened"
  belongs_to :taxon_concepts
end
