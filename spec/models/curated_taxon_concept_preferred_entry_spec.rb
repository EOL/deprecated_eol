require "spec_helper"

describe CuratedTaxonConceptPreferredEntry do

  describe '.best_classification' do
  end

  describe '.for_taxon_concept' do

    before(:all) do
      populate_tables(:visibilities, :vetted)
    end

    it 'returns nil if there is nothing for this concept' do
      expect(CuratedTaxonConceptPreferredEntry.
        for_taxon_concept(TaxonConcept.gen)).to be_nil
    end

    it 'returns nil if the CTCPE has no hierarchy entry' do
      taxon_concept = TaxonConcept.gen
      CuratedTaxonConceptPreferredEntry.gen(taxon_concept: taxon_concept,
                                            hierarchy_entry_id: 0)
      expect(CuratedTaxonConceptPreferredEntry.
        for_taxon_concept(taxon_concept)).to be_nil
    end

    it 'returns CTCPE when hierarchy entry is published' do
      taxon_concept = TaxonConcept.gen
      entry = HierarchyEntry.gen(taxon_concept: taxon_concept)
      ctcpe =
        CuratedTaxonConceptPreferredEntry.gen(taxon_concept: taxon_concept,
                                              hierarchy_entry: entry)
      entry = HierarchyEntry.gen(taxon_concept: taxon_concept,
                                 published: true)
      expect(CuratedTaxonConceptPreferredEntry.
        for_taxon_concept(taxon_concept)).to eq(ctcpe)
    end

    it 'returns nil when hierarchy entry is NOT published' do
      taxon_concept = TaxonConcept.gen
      entry = HierarchyEntry.gen(taxon_concept: taxon_concept,
                                 published: false)
      ctcpe =
        CuratedTaxonConceptPreferredEntry.gen(taxon_concept: taxon_concept,
                                              hierarchy_entry: entry)
      expect(CuratedTaxonConceptPreferredEntry.
        for_taxon_concept(taxon_concept)).to be_nil
    end

  end

end
