# NOTE: Really, this should be a request spec.
describe "Collections API V1" do

  before(:all) do
    @key = "1234123"
    @user = User.gen(api_key: @key)
    DataType.create_enumerated
    License.create_enumerated
  end

  def encode(token)
    ActionController::HttpAuthentication::Token.encode_credentials(token)
  end

  let(:json) { JSON.parse(response.body) }

  describe "GET /wapi/collections" do
    before(:all) do
      @collection = Collection.gen
      50.times do
        @collection.collection_items << CollectionItem.gen
      end
    end

    before do
      # http://stackoverflow.com/questions/12041091/ror-testing-an-action-that-uses-http-token-authentication
      get '/wapi/collections', {}, { "HTTP_AUTHORIZATION" => encode(@key) }
    end

    it "returns the collections" do
      expect(json.map { |c| c["name"]}).to include(@collection.name)
    end
    
    it "should return 30 collections per page" do
      get '/wapi/collections'
      expect(json.count).to eq(30)
    end
    
    it "should return less than 30 per page if requested by user" do
      get '/wapi/collections', {per_page: 20}
      expect(json.count).to eq(20)
    end
    
    it "should return less than 30 in second page" do
      get '/wapi/collections', {page: 2}
      expect(json.count).to be < 30 #total number of collections are 51 so second page will have 21 collections in this case
    end
    
    it "should return less than 20 in last page where the user specufy 20 per page" do
      get '/wapi/collections', {per_page: 20, page: 3}
      expect(json.count).to eq(Collection.count % 20 ) #total number is 51 so in third page we will have 11 collections only 
    end
  end

  describe "Create new collection"do
    describe "POST with no name" do
      before do
        Collection.delete_all
        post '/wapi/collections',
          {},
          { "HTTP_AUTHORIZATION" => encode(@key) }
      end
      it "FAILS" do
        expect(json).to include("errors")
      end
      it "does not create a collection" do
        expect(Collection.count).to eq(0)
      end
    end
  
    describe "POST with name" do
      before do
        Collection.delete_all
        post '/wapi/collections',
          { collection: { name: "something important"} },
          { "HTTP_AUTHORIZATION" => encode(@key) }
      end
      it "creates a collection" do
        expect(Collection.count).to be(1)
      end
      it "sets the owner" do
        expect(Collection.last.users).to include(@user)
      end
    end
  
    describe "POST with full example" do
      let(:taxon) { TaxonConcept.gen }
      let(:data_object) { DataObject.gen }
      before do
        Collection.delete_all
        $FOO = true
        post '/wapi/collections',
          { collection: {
            name: "Something cool",
            description: "lots of important stuff here",
            collection_items: [
              {"annotation" => "Something interesting",
               "collected_item_id" => taxon.id,
               "collected_item_type" => "TaxonConcept",
               "sort_field" => "12"
              },
              {"annotation" => "Something else",
               "collected_item_id" => data_object.id,
               "collected_item_type" => "DataObject"
              }
            ]
          } },
          { "HTTP_AUTHORIZATION" => encode(@key) }
      end
  
      # Using many assertions in one #it block because it's expensive to run.
      it "creates the exepected collection" do
        expect(Collection.count).to be(1)
        collection = Collection.last
        expect(collection.name).to eq("Something cool")
        expect(collection.description).to eq("lots of important stuff here")
        items = collection.collection_items
        expect(items.count).to eq(2)
        pairs = items.map {|ci| [ci.collected_item_id, ci.collected_item_type] }
        expect(pairs).to include([taxon.id, "TaxonConcept"])
        expect(pairs).to include([data_object.id, "DataObject"])
        expect(items.map(&:sort_field)).to include("12")
        expect(items.map(&:added_by_user)).to eq([@user, @user])
        expect(collection.users).to include(@user)
      end
  
    end
  end
  
  describe "Update collection" do
    before :all do
      @taxon = TaxonConcept.gen
      @data_object = DataObject.gen
      Collection.delete_all
      post '/wapi/collections',
        {collection: {
          name: "name",
          collection_items: [
            {"annotation" => "item1",
             "collected_item_id" => @taxon.id,
             "collected_item_type" => "TaxonConcept",
             "sort_field" => "12"
            },
            {"annotation" => "item2",
             "collected_item_id" => @data_object.id,
             "collected_item_type" => "DataObject"
            }
          ]
        }},
        { "HTTP_AUTHORIZATION" => encode(@key) }
        @collection = Collection.last
    end
    
    it "should deny access to unauthorized users" do
      put "/wapi/collections/#{@collection.id}", {collection: {name: "another_name"}}
      expect(response.response_code) == :unauthorized
    end
    
    it "should deny access to wrong token user" do
      put "/wapi/collections/#{@collection.id}", {collection: {name: "another_name"}}, {"HTTP_AUTHORIZATION" => encode("wrong_key")}
      expect(response.response_code) == :unauthorized
    end
    
    it "should update the collection name" do
      put "/wapi/collections/#{@collection.id}", {collection: {name: "another_name"}}, {"HTTP_AUTHORIZATION" => encode(@key)}
      expect(@collection.reload.name).to eq("another_name")
    end
    
    it "gives a message if the collection does not exist" do 
      non_existing_id = Collection.last.id+1
      put "/wapi/collections/#{non_existing_id}", {collection: {name: "another_name"}}, {"HTTP_AUTHORIZATION" => encode(@key)}
      expect(response.body).to include(I18n.t("collection_not_existing", collection: non_existing_id))
    end
end 
  
  describe "Delete collection" do
    before :all do
      taxon =  TaxonConcept.gen
      Collection.delete_all
      $FOO = true
      post '/wapi/collections',
        {collection: {
          name: "name",
          collection_items: [
            {"annotation" => "item1",
             "collected_item_id" => taxon.id,
             "collected_item_type" => "TaxonConcept",
             "sort_field" => "12"
            }
          ]
        }},
        { "HTTP_AUTHORIZATION" => encode(@key) }
        @collection = Collection.last
    end
    
    it "should deny access to unauthorized user" do
      delete "/wapi/collections/#{@collection.id}", {collection: {name: "another_name"}}
      expect(response.response_code) == :unauthorized
    end
    
    it "should deny access to wrong token user" do
      delete "/wapi/collections/#{@collection.id}", {collection: {name: "another_name"}}, {"HTTP_AUTHORIZATION" => encode("wrong_key")}
      expect(response.response_code) == :unauthorized
    end
    
    it "should delete the list and returns success" do
      delete "/wapi/collections/#{@collection.id}", {collection: {name: "another_name"}}, {"HTTP_AUTHORIZATION" => encode(@key)}
      expect(response.body).to include("deleted")
    end

    it "gives a message if the collection does not exist" do 
      delete "/wapi/collections/0", {collection: {name: "another_name"}},
      {"HTTP_AUTHORIZATION" => encode(@key)}
      expect(response.body).to include(I18n.t("collection_not_existing", collection: 0))
    end
  end
end
