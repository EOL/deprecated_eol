class TaxonConceptsFlattened < ActiveRecord::Base
  set_table_name "taxon_concepts_flattened"
  belongs_to :taxon_concepts
end
