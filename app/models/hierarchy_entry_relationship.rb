# Used during harvesting (only). These eventually make their way to Solr, but
# that's it. We use Solr for the matching queries, because it's "faster than
# SQL" (IMO, only because we don't index/denormalize in SQL properly, but hey.)
class HierarchyEntryRelationship < ActiveRecord::Base
  self.primary_keys = :hierarchy_entry_id_1, :hierarchy_entry_id_2

  belongs_to :from_hierarchy_entry, class_name: "HierarchyEntry",
    foreign_key: "hierarchy_entry_id_1", inverse_of: :relationships_from
  belongs_to :to_hierarchy_entry, class_name: "HierarchyEntry",
    foreign_key: "hierarchy_entry_id_2", inverse_of: :relationships_to

  def to_hash
    {
      hierarchy_entry_id_1: hierarchy_entry_id_1,
      taxon_concept_id_1: from_hierarchy_entry.taxon_concept_id,
      hierarchy_id_1: from_hierarchy_entry.hierarchy_id,
      visibility_id_1: from_hierarchy_entry.visibility_id,
      hierarchy_entry_id_2: hierarchy_entry_id_2,
      taxon_concept_id_2: to_hierarchy_entry.taxon_concept_id,
      hierarchy_id_2: to_hierarchy_entry.hierarchy_id,
      visibility_id_2: to_hierarchy_entry.visibility_id,
      same_concept: from_hierarchy_entry.taxon_concept_id == to_hierarchy_entry.taxon_concept_id,
      relationship: relationship,
      confidence: score
    }
  end
end
