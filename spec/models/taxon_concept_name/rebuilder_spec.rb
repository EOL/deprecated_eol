describe TaxonConceptName::Rebuilder do
  describe "#by_taxon_concept_id" do
    # You need HEntries (with corresponding entries in names) mapped to the tc
    # ids you pass in. They need to be either published or preview. Most of them
    # should be linked to synonyms (those are the scientific names and common
    # names—just not canonical names). Canonical forms need to have entries in
    # the names table as well as canonical_forms. The languages used for common
    # names need to have an iso_639_1 value.
    it "should store unpublished names from Hierarchy.ubio"
    it "should store scientific names"
    it "should store canonical forms"
    it "should store preferred common names"
    it "should store non-preferred common names"
    it "should get names from unpublished, preview entries"
    it "should NOT get names from unpublished, invisible entries"
  end
end
