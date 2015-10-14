# Used during harvesting (only).
class HierarchyEntryRelationship < ActiveRecord::Base
  self.primary_keys = :hierarchy_entry_id_1, :hierarchy_entry_id_2

  # Great googly-moogly!! ...Alas, this is straight outta PHP :(
  scope :for_hashes, -> {
    select("he1.id id1, he1.taxon_concept_id taxon_concept_id_1, "\
      "he1.hierarchy_id hierarchy_id_1, he1.visibility_id visibility_id_1, "\
      "he2.id id2, he2.taxon_concept_id taxon_concept_id_2, "\
      "he2.hierarchy_id hierarchy_id_2, he2.visibility_id visibility_id_2, "\
      "he1.taxon_concept_id = he2.taxon_concept_id same_concept, "\
      "hierarchy_entry_relationships.relationship, "\
      "hierarchy_entry_relationships.score").
    joins("JOIN hierarchy_entries he1 ON "\
      "(hierarchy_entry_relationships.hierarchy_entry_id_1 = he1.id) JOIN "\
      "hierarchy_entries he2 ON "\
      "(hierarchy_entry_relationships.hierarchy_entry_id_2 = he2.id)")
  }

  def to_hash
    {
      hierarchy_entry_id_1: self["id1"],
      taxon_concept_id_1: self["taxon_concept_id_1"],
      hierarchy_id_1: self["hierarchy_id_1"],
      visibility_id_1: self["visibility_id_`1"],
      hierarchy_entry_id_2: self["id2"],
      taxon_concept_id_2: self["taxon_concept_id_2"],
      hierarchy_id_2: self["hierarchy_id_2"],
      visibility_id_2: self["visibility_id_2"],
      same_concept: self["same_concept"],
      relationship: self["relationship"],
      confidence: self["score"]
    }
  end
end
