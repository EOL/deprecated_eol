require "spec_helper"

describe CuratedTaxonConceptPreferredEntry do

  describe '.best_classification' do
  end

  describe '.for_taxon_concept' do

    let(:ctcpe) { CuratedTaxonConceptPreferredEntry.new }
    let(:taxon_concept) { build_stubbed(TaxonConcept) }
    let(:entry) { build_stubbed(TaxonConcept) }
    
    before do
      allow(CuratedTaxonConceptPreferredEntry).to receive(:find_by_taxon_concept_id) { ctcpe }
      allow(ctcpe).to receive(:hierarchy_entry) { entry }
    end

    it 'returns nil if there is nothing for this concept' do
      allow(CuratedTaxonConceptPreferredEntry).to receive(:find_by_taxon_concept_id) { nil }
      expect(CuratedTaxonConceptPreferredEntry.for_taxon_concept(taxon_concept)).to be_nil
    end

    it 'returns nil if the CTCPE has no hierarchy entry' do
      allow(ctcpe).to receive(:hierarchy_entry) { nil }
      expect(CuratedTaxonConceptPreferredEntry.for_taxon_concept(taxon_concept)).to be_nil
    end

    it 'returns CTCPE when hierarchy entry is published' do
      allow(entry).to receive(:published?) { true }
      expect(CuratedTaxonConceptPreferredEntry.for_taxon_concept(taxon_concept)).to eq(ctcpe)
      expect(entry).to have_received(:published?)
    end

  end

end
