describe Hierarchy do
  before(:all) do 
    Rank.gen_if_not_exists(label: 'kingdom', rank_group_id: 0)
    Rank.gen_if_not_exists(label: 'phylum', rank_group_id: 0)
    Rank.gen_if_not_exists(label: 'class', rank_group_id: 0)
    Rank.gen_if_not_exists(label: 'order', rank_group_id: 0)
  end
  describe Hierarchy::Relator do 
    let(:hierarchy) { Hierarchy.gen }
    subject { Hierarchy::Relator.new(hierarchy) }
  
    # Again, I suggest for these specs you load a bunch of data to satisfy all of
    # the tests, run it ONCE, and check all of the results in separate assertions.
    # It's too expensive (it's VERY expensive) to keep running it over and over.
    # Remember, almost all of the data used for matches comes from the
    # HierarchyEntries Solr core, so you will have to load that up to run your
    # specs. Probably best to just build the entries/hierarchies and run
    # SolrCore::HierarchyEntries.reindex_hierarchy on each hierarchy... though you
    # could conceivably create (almost) ALL of the test data just by pushing
    # hashes into the Solr core. That would be faster, but uglier. Your call.
    describe "#relate" do
      # This is the hierarchy you will be using to test the relator (against
      # others):
      let(:hierarchy) { Hierarchy.gen }
      # Only specific ids are allowed to match synonyms:
      let(:synonym_hierarchy) { Hierarchy.gen(id: 123) }
      # Synonyms in this one should NOT be matched:
      let(:non_synonym_hierarchy) { Hierarchy.gen(id: 124) }
      it "should NOT match entries both which are both in complete hierarchies"
      it "should NOT match a species with a genus of the same name"
      it "should NOT match synonyms from hierarchy 123 if the entry is a virus"
      # Meaning: you create an entry in :synonym_hierarchy with a name of "Syn
      # name", then an entry in :hierarchy with the name "Syn name", but give that
      # entry a kingdom ancestor named "Viruses".
      it "should score lowly if entry has no ancestors"
      it "should score highly if family ranks match"
      it "should score moderately if class ranks match"
      it "should score lowly if phylum ranks match"
      it "should score very lowly if kingdom matches (both entries must be "\
        "phylum rank)"
      it "should match moderately if canonical_form matches synonym"
      it "should match highly if name matches synonym"
      it "adds relationships (with a score of 1) stored in "\
        "CuratedHierarchyEntryRelationship"
      it "should store matches in HierarchyEntryRelationship table"
      it "should index matches in HierarchyEntryRelationships Solr core"
    end
  end
end