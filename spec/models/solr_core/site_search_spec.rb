describe SolrCore::SiteSearch do
  before(:all) do
    populate_tables(:visibilities, :vetted, :licenses, :data_types)
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
        he = HierarchyEntry.gen(taxon_concept_id: @taxon.id)
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
        @richness_score = 
          TaxonConceptMetric.create(taxon_concept: @taxon, richness_score: 50)
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
      it "should store richness_score" do
         doc = @indexer.select("resource_id:#{@taxon.id} AND "\
          "resource_type:TaxonConcept")["response"]["docs"].first
          expect(doc["richness_score"]).to eq(@richness_score.richness_score)
      end
    end

    describe "with data objects" do
      def get_data_object_doc(indexer, id, string, type)
        docs = indexer.select("keyword_type: \"#{string}\" AND resource_id: #{id}")["response"]["docs"]
        docs.find { |doc| doc["resource_type"].include?(type) }
      end
      before(:all) do
        DataObject.delete_all
        @agent = Agent.gen(full_name: "fullname", given_name: "givenname", family_name: "familyname")
        @user = User.gen(username: "username", given_name: "givenname", family_name: "familyname")
        @data_objects = []
        # Image, Article, Map
        [DataType.image_type_ids.first, DataType.text_type_ids.first, DataType.map_type_ids.first].each do |type|
          data_obj = DataObject.gen(object_title: "object title", description: "description",
          rights_statement: "rights statement", rights_holder: "rights holder",
          bibliographic_citation: "bibliographic citation", location: "location",
          data_type_id: type, published: 1)
          DataObjectsHierarchyEntry.gen(data_object_id: data_obj.id,
          hierarchy_entry_id: HierarchyEntry.gen.id, visibility_id: Visibility.visible.id)
          AgentsDataObject.gen(agent_id: @agent.id, data_object_id: data_obj.id) if type == DataType.image_type_ids.first
          UsersDataObject.gen(user_id: @user.id, data_object_id: data_obj.id) if type ==  DataType.text_type_ids.first || DataType.map_type_ids.first
          @data_objects << data_obj
        end
        @indexer = SolrCore::SiteSearch.new
        @indexer.index_type(DataObject, [@data_objects[0].id, @data_objects[1].id, @data_objects[2].id])
      end
      it "should add object title" do
        data_obj_doc = get_data_object_doc(@indexer, @data_objects[0].id, "object_title", "Image")
        expect(data_obj_doc["keyword"].include?(@data_objects[0].object_title)).to be_true
      end
      it "should add description" do
         data_obj_doc = get_data_object_doc(@indexer, @data_objects[0].id, "description", "Image")
        expect(data_obj_doc["keyword"].include?(@data_objects[0].description)).to be_true
      end
      it "should add rights statement" do
        data_obj_doc = get_data_object_doc(@indexer, @data_objects[0].id, "rights_statement", "Image")
        expect(data_obj_doc["keyword"].include?(@data_objects[0].rights_statement)).to be_true
      end
      it "should add rights holder" do
        data_obj_doc = get_data_object_doc(@indexer, @data_objects[0].id, "rights_holder", "Image")
        expect(data_obj_doc["keyword"].include?(@data_objects[0].rights_holder)).to be_true
      end
      it "should add bibliographic_citation" do
        data_obj_doc = get_data_object_doc(@indexer, @data_objects[0].id, "bibliographic_citation", "Image")
        expect(data_obj_doc["keyword"].include?(@data_objects[0].bibliographic_citation)).to be_true
      end
      it "should add location" do
        data_obj_doc = get_data_object_doc(@indexer, @data_objects[0].id, "location", "Image")
        expect(data_obj_doc["keyword"].include?(@data_objects[0].location)).to be_true
      end
      it "should add associated agents" do
        name = SolrCore.string("#{@agent.full_name} #{@agent.given_name} #{@agent.family_name}")
        docs = @indexer.select("keyword_type: \"agent\" AND resource_id: #{@data_objects[0].id}")["response"]["docs"]
        required_doc = docs.find { |doc| doc["keyword"].include?("#{name}") }
        expect(required_doc).not_to be_nil
      end
      it "should add associated users full name" do
        docs = @indexer.select("keyword_type: \"agent\" AND resource_id: #{@data_objects[1].id}")["response"]["docs"]
        required_doc = docs.find { |doc| doc["keyword"].include?("#{@user.full_name}") }
        expect(required_doc).not_to be_nil
      end
      it "should add associated users user name" do
        docs = @indexer.select("keyword_type: \"agent\" AND resource_id: #{@data_objects[1].id}")["response"]["docs"]
        required_doc = docs.find { |doc| doc["keyword"].include?("#{@user.username}") }
        expect(required_doc).not_to be_nil
      end
      it "should give images a weight around 60" do
        data_obj_doc = @indexer.select("resource_id: #{@data_objects[0].id} AND resource_type: \"Image\"")["response"]["docs"].first
        expect(data_obj_doc["resource_weight"]).to equal(60)
      end
      it "should give articles a weight around 40" do
        data_obj_doc = @indexer.select("resource_id: #{@data_objects[1].id} AND resource_type: \"Text\"")["response"]["docs"].first
        expect(data_obj_doc["resource_weight"]).to equal(40)
      end
      it "should give maps a weight around 100" do
        data_obj_doc = @indexer.select("resource_id: #{@data_objects[2].id} AND resource_type: \"DataObject\"")["response"]["docs"].first
        expect(data_obj_doc["resource_weight"]).to equal(100)
      end
    end
  end
end
