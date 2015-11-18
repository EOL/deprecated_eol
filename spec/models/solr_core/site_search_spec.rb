describe SolrCore::SiteSearch do
  before(:all) do
    populate_tables(:visibilities, :vetted)
    Language.create_english
  end
  describe "#index_type" do
    describe "with taxon concepts" do
      def get_taxon_doc(indexer, id, string)
        docs = indexer.select("keyword:'#{string}'")["response"]["docs"]
        docs.find { |doc| doc["resource_id"] == id &&
          doc["resource_type"].include?("TaxonConcept") }
      end

      before(:all) do
        # This ONLY reads taxon_concept_names for what relationships. ...well, it
        # also uses names and languages, but that's minor.
        @taxon = TaxonConcept.gen
        @ancestor =
          TaxonConceptsFlattened.create(taxon_concept_id: @taxon.id,
            ancestor_id: 1245)
        @en_pref =
          TaxonConceptName.gen(taxon_concept: @taxon, vern: true, preferred: true,
            language: Language.english)
        @en =
          TaxonConceptName.gen(taxon_concept: @taxon, vern: true, preferred: false,
            language: Language.english)
        name = Name.gen_if_not_exists(string: "Something a")
        # NOTE: surrogates are marked in usual ways. One of them is the letter
        # "a" by itself in the name. Others are quotes, underscores, etc. See
        # Name.is_surrogate_or_hybrid?. We could stub that here, but it seemed
        # more trouble than it was worth. NOT stubbing it DOES make this a more
        # fragile spec. :|
        @surrogate =
          TaxonConceptName.gen(taxon_concept: @taxon, vern: false,
            preferred: false, source_hierarchy_entry_id: 1, name: name)
        @sci =
          TaxonConceptName.gen(taxon_concept: @taxon, vern: false,
            preferred: true, source_hierarchy_entry_id: 1, language_id: 0)
        @synonym =
          TaxonConceptName.gen(taxon_concept: @taxon, vern: false,
            preferred: false, source_hierarchy_entry_id: 1, language_id: 0)
        @old_doc = {
          "resource_id" => @taxon.id,
          "resource_unique_key" => "TaxonConcept_#{@taxon.id}",
          "top_image_id" => 12,
          "richness_score" => 23.0,
          "keyword_type" => "PreferredCommonName",
          "language" => "en",
          "resource_weight" => 2,
          "ancestor_taxon_concept_id" => [30],
          "keyword" => ["Shouldnotbehere"],
          "resource_type" => ["TaxonConcept"]
        }
        @indexer = SolrCore::SiteSearch.new
        @indexer.connection.add(@old_doc)
        @indexer.connection.commit
        @indexer.index_type(TaxonConcept, [@taxon.id])
      end

      it "should replace an index that was already there" do
        num = @indexer.select("keyword:Shouldnotbehere")["response"]["numFound"]
        expect(num).to eq(0)
      end
      it "should add preferred common names (with a weight of 2)" do
        taxon_doc = get_taxon_doc(@indexer, @taxon.id, @en_pref.name.string)
        expect(taxon_doc).to_not be_nil
        expect(taxon_doc["resource_weight"]).to eq(2)
      end
      it "should add non-preferred common names (with a weight of 4)" do
        taxon_doc = get_taxon_doc(@indexer, @taxon.id, @en.name.string)
        expect(taxon_doc).to_not be_nil
        expect(taxon_doc["resource_weight"]).to eq(4)
      end
      it "should add surrogate names (with a weight of 500)" do
        taxon_doc = get_taxon_doc(@indexer, @taxon.id, @surrogate.name.string)
        expect(taxon_doc).to_not be_nil
        expect(taxon_doc["resource_weight"]).to eq(500)
      end
      it "should add preferred scientific names (with a weight of 1)" do
        taxon_doc = get_taxon_doc(@indexer, @taxon.id, @sci.name.string)
        expect(taxon_doc).to_not be_nil
        expect(taxon_doc["resource_weight"]).to eq(1)
      end
      it "should add synonyms (with a weight of 3)" do
        # NOTE: this does NOT read the synonyms table; just TCN.
        taxon_doc = get_taxon_doc(@indexer, @taxon.id, @synonym.name.string)
        expect(taxon_doc).to_not be_nil
        expect(taxon_doc["resource_weight"]).to eq(3)
      end
      it "should store ancestors of taxa" do
        # These are stored in an array called ancestor_taxon_concept_id
        doc = @indexer.select("resource_id:#{@taxon.id} AND "\
          "resource_type:TaxonConcept")["response"]["docs"].first
        expect(doc["ancestor_taxon_concept_id"].include?(1245)).to be_true
      end
      it "should store richness_score"
      it "should record top_images"
    end

    describe "with data objects" do
      it "should add object title"
      it "should add description"
      it "should add rights statement"
      it "should add rights holder"
      it "should add bibliographic_citation"
      it "should add location"
      it "should add associated agents"
      it "should add associated users (full name + username)"
      it "should give images a weight around 60"
      it "should give articles a weight around 40"
      it "should give maps a weight around 100"
    end
  end
end
