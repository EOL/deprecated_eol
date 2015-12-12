describe "SolrCore::HierarchyEntries" do
  
  before(:all) do
    populate_tables(:visibilities, :vetted, :synonym_relations)
    Language.create_english
    Language.gen_if_not_exists(:label => 'Unknown')
    Language.gen_if_not_exists(:label => 'Scientific Name')
    @rank = Rank.gen_if_not_exists(label: 'class')
    @parent_rank = Rank.gen_if_not_exists(label: 'regn.')
    @common_name_relation = SynonymRelation.common_name_ids.first
    Hierarchy.gen(label: "Encyclopedia of Life Contributors")
  end
  
  describe ".reindex_hierarchy" do
    before(:all) do
      @hierarchy = Hierarchy.gen
      #names and canonical forms
      @canonical_form = CanonicalForm.gen
      @parent_canonical_form = CanonicalForm.gen
      @scientific_canonical_form = CanonicalForm.gen
      @name = Name.gen(ranked_canonical_form_id: @canonical_form.id)
      @parent_name = Name.gen(ranked_canonical_form_id: @parent_canonical_form.id)
      @scientific_name = Name.gen(ranked_canonical_form_id: @scientific_canonical_form.id)
      # parent hierarchy entry and entry
      @parent = HierarchyEntry.gen(name_id: @parent_name.id, parent_id: 0, hierarchy_id: @hierarchy.id, rank_id: @parent_rank.id)
      @he = HierarchyEntry.gen(name_id: @name.id, parent_id: @parent.id, hierarchy_id: @hierarchy.id, rank_id: @rank.id)
      #synonyms
      @synonym_of_common_name = Synonym.gen(name_id: @name.id, hierarchy_entry_id: @he.id, synonym_relation_id: @common_name_relation)
      @synonym_of_scientific_name = Synonym.gen(name_id: @scientific_name.id, hierarchy_entry_id: @he.id, synonym_relation_id: 100, language_id: Language.scientific.id)
      @indexer = SolrCore::HierarchyEntries.new
      @indexer.reindex_hierarchy(@hierarchy)
    end
    # ...This is an expensive thing to do, so I think it's best to set up a
    # bunch of stuff before and just test all of it without re-running it.
    it "index an entry with its ancestor kingdom" do
      res_count = @indexer.select("hierarchy_id:#{@hierarchy.id}")["response"]["numFound"]
      expect(res_count).to equal(2)
    end
    # There are other ranks to test, but this is enough for now. Remember to add
    # the ancestor through HierarchyEntriesFlattened.
    it "index an entry with its canonical form" do
      expect(@indexer.select("canonical_form:#{SolrCore::HierarchyEntries.
        clean_canonical_form(@canonical_form.string)}")["response"]["docs"]).not_to be_nil
    end
    
    it "index an entry with its original canonical form string" do
      expect(@indexer.select("canonical_form_string:#{@canonical_form.string}")["response"]["docs"]).
        not_to be_nil
    end
    
    it "index an entry with its synonyms" do
      docs = @indexer.select("synonym:#{@name.string}")["response"]["docs"]
      docs.first["synonym"].include? @scientific_name.string
    end
    
    it "index an entry with its synonym_canonicals" do
      expect(@indexer.select("synonym_canonical:#{@scientific_canonical_form.string}")["response"]["docs"]).
        not_to be_nil
    end
    
    it "index an entry with its common_names" do
      expect(@indexer.select("common_name:#{@name.string}")["response"]["docs"]).
        not_to be_nil
    end
    
    it "index an entry with its id" do
      expect(@indexer.select("id:#{@he.id}")["response"]["docs"]).
        not_to be_nil
    end
    
    it "index an entry with its parent_id" do
      expect(@indexer.select("parent_id:#{@parent.id}")["response"]["docs"]).
        not_to be_nil
    end
    
    it "index an entry with its hierarchy_id" do
      expect(@indexer.select("hierarchy_id:#{@hierarchy.id}")["response"]["docs"]).
        not_to be_nil
    end
    
    it "index an entry with its rank_id" do
      expect(@indexer.select("rank_id:#{@rank.id}")["response"]["docs"]).
        not_to be_nil
    end
    
    it "index an entry with its taxon_concept_id" do
      expect(@indexer.select("rank_id:#{@rank.id}")["response"]["docs"]).
        not_to be_nil
    end
    
    it "should index the 'regn.' as a kingdom" do
      expect(@indexer.select("kingdom:#{@parent_canonical_form.string}")["response"]["docs"]).
        not_to be_nil
    end
  
    it "should call .clean_canonical_form on the canonical_form of an entry and synonym" do
      SolrCore::HierarchyEntries.should_receive(:clean_canonical_form).once.
        with(@parent_canonical_form.string)
      SolrCore::HierarchyEntries.should_receive(:clean_canonical_form).once.
        with(@canonical_form.string)
      SolrCore::HierarchyEntries.should_receive(:clean_canonical_form).once.
        with(@scientific_canonical_form.string)
      @indexer.reindex_hierarchy(@hierarchy)
    end
  end

  describe ".clean_canonical_form" do
    it "should set a canonical_form of 'Foo bar sp baz' to 'Foo bar sp'" do
      expect(SolrCore::HierarchyEntries.clean_canonical_form("Foo bar sp baz")).to eq("Foo bar sp")
    end
    it "should set a canonical_form of 'Foo bar ssp baz var boozer' to "\
      "'Foo bar baz boozer'" do
      expect(SolrCore::HierarchyEntries.clean_canonical_form("Foo bar ssp baz var boozer")).
        to eq("Foo bar baz boozer")
      end
  end
end
