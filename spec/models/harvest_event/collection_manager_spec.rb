describe HarvestEvent::CollectionManager do
  describe "#sync" do
    # NOTE: that the data must be in the database for this to work. Custom SQL,
    # of course.
    describe "when the collection is new" do
      it "should have the proper attributes"
      # Description, logo, name, published flag.
      it "should have the proper user"
      it "should have the proper item count"
      it "should destroy any existing preview collection"
      it "should include data objects"
      it "should include taxon concepts"
      it "should be indexed in Solr"
    end
    describe "when the collection already existed" do
      # This requires an OLD harvest event with a set of entries which are
      # already in a collection.
      it "should add new data objects"
      it "should add new taxa"
      it "should remove data objects which are not in the latest harvest"
      it "should remove taxa which are not in the latest harvest"
      it "should have the proper item count (trickier this time)"
    end
  end
end
