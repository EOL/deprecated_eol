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
