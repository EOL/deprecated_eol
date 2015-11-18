describe "TaxonConcept::Cleanup" do
  describe ".unpublish_and_hide_by_entry_ids" do
    it "should call .unpublish_concepts_with_no_published_entries with ids"
    it "should call .untrust_concepts_with_no_visible_trusted_entries with ids"
    # NOTE: remember NOT to really call either method; just use expects.
  end

  describe ".unpublish_concepts_with_no_published_entries" do
    it "should unpublish a published concept with only unpublished entries"
    it "should NOT unpublish a published concept with a published entry"
  end

  describe ".untrust_concepts_with_no_visible_trusted_entries" do
    it "should untrust a trusted concept with only untrusted invisible entries"
    it "should NOT untrust a trusted concept with a visible entry"
    it "should NOT untrust a trusted concept with a trusted entry"
  end
end
