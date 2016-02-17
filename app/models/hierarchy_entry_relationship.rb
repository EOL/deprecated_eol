# Used during harvesting (only). These eventually make their way to Solr, but
# that's it. ...Why? TODO: the numbered IDs are silly. Use from/to.
class HierarchyEntryRelationship < ActiveRecord::Base
  self.primary_keys = :hierarchy_entry_id_1, :hierarchy_entry_id_2

  belongs_to :from_hierarchy_entry, class_name: "HierarchyEntry",
    foreign_key: "hierarchy_entry_id_1"
  belongs_to :to_hierarchy_entry, class_name: "HierarchyEntry",
    foreign_key: "hierarchy_entry_id_2"

  # Great googly-moogly!! ...Alas, this is straight outta PHP :( TODO: improve
  # these using the new relationships (above); there is a pattern like this
  # already in Hierarchy::Relator#add_curator_assertions. (But note that you
  # will have to handle all of the names of the fields returned, once you do
  # that!)
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
  scope :by_hierarchy_for_hashes, ->(hier_id) { for_hashes.
    where(["he1.hierarchy_id = ? OR he2.hierarchy_id = ?", hier_id, hier_id]) }

  def to_hash
    {
      hierarchy_entry_id_1: self["id1"],
      taxon_concept_id_1: self["taxon_concept_id_1"],
      hierarchy_id_1: self["hierarchy_id_1"],
      visibility_id_1: self["visibility_id_1"],
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
