describe "SolrCore::HierarchyEntries" do
  describe ".reindex_hierarchy" do
    # ...This is an expensive thing to do, so I think it's best to set up a
    # bunch of stuff before and just test all of it without re-running it.
    it "index an entry with its ancestor kingdom"
    # There are other ranks to test, but this is enough for now. Remember to add
    # the ancestor through HierarchyEntriesFlattened.
    it "index an entry with its canonical form"
    it "index an entry with its original canonical form string"
    it "index an entry with its synonyms"
    it "index an entry with its synonym_canonicals"
    it "index an entry with its common_names"
    it "index an entry with ids for its parent, hierarchy, rank, and "\
      "taxon_concept"
    it "index an entry with "
    it "should index the 'regn.' as a kingdom"
    # NOTE: there are a bunch of other ones like this, but if this works, let's
    # assume the others do (for now).
    it "should call .clean_canonical_form on the canonical_form of an entry"
    it "should call .clean_canonical_form on the canonical_form of a synonym"
    # NOTE: Use should receive(), here!
  end

  describe ".clean_canonical_form"
    it "should set a canonical_form of 'Foo bar sp baz' to 'Foo bar sp'"
    it "should set a canonical_form of 'Foo bar ssp baz var boozer' to "\
      "'Foo bar baz boozer'"
  end
end
