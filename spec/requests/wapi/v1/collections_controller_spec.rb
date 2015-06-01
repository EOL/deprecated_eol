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
    end

    before do
      # http://stackoverflow.com/questions/12041091/ror-testing-an-action-that-uses-http-token-authentication
      get '/wapi/collections', {}, { "HTTP_AUTHORIZATION" => encode(@key) }
    end

    it "returns the collections" do
      expect(json.map { |c| c["name"]}).to include(@collection.name)
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
    
    it "should update the collection items if the passed ones are existed" do
      items = @collection.collection_items
      put "/wapi/collections/#{@collection.id}", {collection: {name: "another_name"}, collection_items:[
        {"annotation" => "item1_updated", "collected_item_id" => @taxon.id, "collected_item_type" => "TaxonConcept", "sort_field" => "12", "id"=> items[items.find_index{|ind| ind.annotation == "item1"}].id}
      ]}, {"HTTP_AUTHORIZATION" => encode(@key)}
      items = (items.reload).map{|name| name.annotation}
      expect(items).to include("item1_updated")
    end
    
    it "should not update the collection items if the passed ones don't exist" do
      items = @collection.collection_items
      put "/wapi/collections/#{@collection.id}", {collection: {name: "another_name"}, collection_items:[
        {"annotation" => "updated_it2", "collected_item_id" => @data_object.id, "collected_item_type" => "DataObject", "id"=> items[items.find_index{|ind| ind.annotation == "item2"}].id},
        {"annotation" => "item1_updated", "collected_item_id" => @taxon.id, "collected_item_type" => "TaxonConcept", "sort_field" => "12", "id"=> "not_found"}
      ]}, {"HTTP_AUTHORIZATION" => encode(@key)}
      expect(response.body).to include("update failed")
      items = (items.reload).map{|name| name.annotation}
      expect(items).not_to include("updated_it2") 
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
  end
end
