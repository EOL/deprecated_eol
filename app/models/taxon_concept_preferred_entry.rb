class TaxonConceptPreferredEntry < ActiveRecord::Base
  belongs_to :taxon_concept
  belongs_to :hierarchy_entry
  belongs_to :published_taxon_concept, class_name: TaxonConcept.to_s, foreign_key: :taxon_concept_id, 
    conditions: Proc.new { "taxon_concepts.published=1" }
  belongs_to :published_hierarchy_entry, class_name: HierarchyEntry.to_s, foreign_key: :hierarchy_entry_id, 
    conditions: Proc.new { "hierarchy_entries.published=1" }
  scope :with_taxon_and_entry, -> { where('taxon_concept_id IS NOT NULL AND hierarchy_entry_id IS NOT NULL') } 
  def self.expire_time
    1.week
  end
  
  def expired?
    return true if !self.updated_at
    ( self.updated_at + TaxonConceptPreferredEntry.expire_time ) < Time.now()
  end
end
