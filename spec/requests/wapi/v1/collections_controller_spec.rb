# NOTE: Really, this should be a request spec.
describe "Collections API V1" do

  def encode(token)
    ActionController::HttpAuthentication::Token.encode_credentials(token)
  end

  let(:json) { JSON.parse(response.body) }

  describe "GET /wapi/collections" do
    before(:all) do
      @collection = Collection.gen
      @user = User.gen(api_key: "1234123")
    end

    before do
      # http://stackoverflow.com/questions/12041091/ror-testing-an-action-that-uses-http-token-authentication
      get '/wapi/collections', {}, { "HTTP_AUTHORIZATION" => encode("1234123") }
    end

    it "returns the collections" do
      expect(json.map { |c| c["name"]}).to include(@collection.name)
    end
  end
end
