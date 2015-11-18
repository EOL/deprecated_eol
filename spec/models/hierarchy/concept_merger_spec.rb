describe Hierarchy::ConceptMerger do
  # NOTE: This will be a REALLY complicated spec to write. It gets all of its
  # info from HierarchyEntryRelationship, though, so your best bet is actually
  # to put all of your test data into that table, then send them to that core
  # (using
  # SolrCore::HierarchyEntryRelationships.reindex_entries_in_hierarchy(@hierarchy,
  # @new_entry_ids)). One complication is that it needs entries in the Hierarchy
  # table (with counts for sorting and flag for complete hierarchies), but you
  # can fake those easily enough. Another exception is that it checks for
  # visibility within hierarchies. The best way to avoid that is to stub
  # HierarchyEntry.exists? to always return false (which causes it to be "okay"
  # in all cases) and then expect certain arguments (taxon_concept_id:
  # taxon_concept_id, hierarchy_id: hierarchy.id, visibility_id: vis_id) to
  # return true. Tricky, but doable. NOTE also that testing whether things match
  # involves stubbing TaxonConcept.merge_ids and using should receive and
  # should_not receive with the ids in question! So lots of stubbing, here! This
  # is a tricky one to test, sorry.

  # For reference, here's the structure of HierarchyEntryRelationships:
  # { "hierarchy_entry_id_1"=>47111837,
  # "taxon_concept_id_1"=>71511, "hierarchy_id_1"=>949,
  # "visibility_id_1"=>1, "hierarchy_entry_id_2"=>20466468,
  # "taxon_concept_id_2"=>71511, "hierarchy_id_2"=>107,
  # "visibility_id_2"=>0, "same_concept"=>true, "relationship"=>"name",
  # "confidence"=>1.0 }
  describe "#merges_for_hierarchy" do
    it "should NOT match curated exclusions with same name and rank"
    # NOTE: this means adding a CuratedHierarchyEntryRelationship with
    # equivalent = 0 between two entries.
    it "should NOT match concepts with a score of 0.249"
    it "should compare incomplete hierarchies to themselves"
    it "should NOT match an entry mapped to a TC which already has an entry "\
      "in that hierarchy"
    # Complicated, but: hierarchy1 -> entry1 -> taxon1. hierarchy2 -> entry2
    # (same name/rank) -> taxon2. taxon2 -> entry3. hierarchy1 -> entry3.
    it "should NOT match and entry in a complete hierarchy with a concept and "\
      "the other entry's concept also has an entry in the first hierarchy."
    # Again, complicated, but I hope it's clear enough what's happening. We
    # don't want these to match because it violates the hierarchy's assertion
    # that these are seperate "things".
    it "should match entries with score of 0.25"
  end
end
