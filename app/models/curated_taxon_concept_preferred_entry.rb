class CuratedTaxonConceptPreferredEntry < ActiveRecord::Base
  belongs_to :taxon_concept
  belongs_to :hierarchy_entry
  belongs_to :user
end
